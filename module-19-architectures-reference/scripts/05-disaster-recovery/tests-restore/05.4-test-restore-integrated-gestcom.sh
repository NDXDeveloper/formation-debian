#!/usr/bin/env bash
# =============================================================================
# Module 19 — Architectures de référence
# Section 19.5.4 — RTO/RPO et dimensionnement
# Fichier : scripts/dr/test-restore-integrated-gestcom.sh
# Licence : CC BY 4.0
# =============================================================================
# Test de restauration intégrée GestCom — bout en bout :
#   1. Création d'un namespace de test isolé
#   2. Restauration de la base de données depuis le backup S3
#   3. Déploiement de l'application via Kustomize overlay dr-test
#   4. Validation fonctionnelle (5 tests : healthz, readyz, login, API, count)
#   5. Nettoyage
#
# Mesure le RTO réel et le compare au SLO. Doit être exécuté
# trimestriellement et après chaque changement majeur d'infrastructure.
#
# Note technique : on évite `((TESTS_PASSED++))` avec `set -e` (l'expression
# `((expr))` retourne exit 1 quand le résultat vaut 0, ce qui est le cas
# AVANT incrémentation quand le compteur est à 0).
#
# Note Bitnami : le chart bitnami/mysql est devenu payant le 28/08/2025.
# Ce script utilise un StatefulSet direct mysql:8.4 pour rester autonome.
# =============================================================================
set -euo pipefail

NAMESPACE="dr-test-gestcom-$(date +%Y%m%d)"
REPORT_FILE="/var/log/dr/test-integrated-gestcom-$(date +%Y%m%d).md"
GLOBAL_START=$(date +%s)

mkdir -p "$(dirname "${REPORT_FILE}")"
exec &> >(tee -a "${REPORT_FILE}")

echo "# Test de restauration intégrée — GestCom — $(date)"
echo ""

# ─── Phase 1 : Création de l'environnement de test ───
echo "## Phase 1 : Environnement de test"
PHASE_START=$(date +%s)

kubectl create namespace "${NAMESPACE}"
kubectl label namespace "${NAMESPACE}" platform.example.com/type=dr-test

kubectl apply -n "${NAMESPACE}" -f platform/tenants/dr-test/

PHASE_DURATION=$(( $(date +%s) - PHASE_START ))
echo "- Durée : ${PHASE_DURATION}s"
echo ""

# ─── Phase 2 : Restauration de la base de données ───
echo "## Phase 2 : Base de données"
PHASE_START=$(date +%s)

# StatefulSet MySQL temporaire (autonome, sans dépendance Bitnami)
cat <<EOF | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: gestcom-db-mysql
spec:
  serviceName: gestcom-db-mysql
  replicas: 1
  selector:
    matchLabels: { app: gestcom-db-mysql }
  template:
    metadata:
      labels: { app: gestcom-db-mysql }
    spec:
      containers:
        - name: mysql
          image: mysql:8.4
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: dr-test
            - name: MYSQL_DATABASE
              value: gestcom_prod
          ports: [{ containerPort: 3306 }]
  volumeClaimTemplates:
    - metadata: { name: data }
      spec:
        accessModes: [ReadWriteOnce]
        resources: { requests: { storage: 5Gi } }
---
apiVersion: v1
kind: Service
metadata: { name: gestcom-db-mysql }
spec:
  selector: { app: gestcom-db-mysql }
  ports: [{ port: 3306 }]
EOF
kubectl -n "${NAMESPACE}" rollout status statefulset/gestcom-db-mysql --timeout=300s

# Restaurer le backup le plus récent depuis S3
LATEST_KEY=$(aws s3 ls s3://entreprise-dr-backups/db-backups/gestcom_prod/ \
    --recursive | sort | tail -1 | awk '{print $4}')

aws s3 cp "s3://entreprise-dr-backups/${LATEST_KEY}" /tmp/dr-test-db.sql.gz.gpg

gpg --batch --passphrase-file /etc/dr/backup-passphrase --decrypt \
    /tmp/dr-test-db.sql.gz.gpg | gunzip | \
    kubectl -n "${NAMESPACE}" exec -i gestcom-db-mysql-0 -- \
    sh -c 'MYSQL_PWD=dr-test mysql -u root gestcom_prod'

PHASE_DURATION=$(( $(date +%s) - PHASE_START ))
echo "- Durée : ${PHASE_DURATION}s"
echo ""

# ─── Phase 3 : Déploiement de l'application ───
echo "## Phase 3 : Déploiement applicatif"
PHASE_START=$(date +%s)

kubectl apply -k k8s-deployments/apps/gestcom/overlays/dr-test/ -n "${NAMESPACE}"
kubectl -n "${NAMESPACE}" rollout status deployment/gestcom --timeout=180s

PHASE_DURATION=$(( $(date +%s) - PHASE_START ))
echo "- Durée : ${PHASE_DURATION}s"
echo ""

# ─── Phase 4 : Validation fonctionnelle ───
echo "## Phase 4 : Validation fonctionnelle"
PHASE_START=$(date +%s)

kubectl -n "${NAMESPACE}" port-forward svc/gestcom 18080:8080 &
PF_PID=$!
sleep 5

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local name="$1"
    local cmd="$2"
    if eval "${cmd}" &>/dev/null; then
        echo "- ✅ ${name}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "- ❌ ${name}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

run_test "Health check" \
    "curl -sf http://localhost:18080/healthz"

run_test "Readiness check (DB connectée)" \
    "curl -sf http://localhost:18080/readyz | grep -q connected"

run_test "Page de login accessible" \
    "curl -sf -o /dev/null -w '%{http_code}' http://localhost:18080/login | grep -q 200"

run_test "API produits répond" \
    "curl -sf http://localhost:18080/api/products?limit=1 | grep -q id"

run_test "Nombre de commandes cohérent" \
    "curl -sf http://localhost:18080/api/orders/count | grep -qE '[0-9]+'"

kill ${PF_PID} 2>/dev/null || true

PHASE_DURATION=$(( $(date +%s) - PHASE_START ))
echo ""
echo "- Tests passés : ${TESTS_PASSED}"
echo "- Tests échoués : ${TESTS_FAILED}"
echo "- Durée : ${PHASE_DURATION}s"
echo ""

# ─── Nettoyage ───
echo "## Nettoyage"
kubectl delete namespace "${NAMESPACE}" --wait=false
rm -f /tmp/dr-test-db.sql.gz.gpg

# ─── Rapport final ───
TOTAL_DURATION=$(( $(date +%s) - GLOBAL_START ))
TOTAL_MINUTES=$(( TOTAL_DURATION / 60 ))

echo ""
echo "## Résultat final"
echo "- Durée totale : ${TOTAL_DURATION}s (${TOTAL_MINUTES} min)"
echo "- Tests : ${TESTS_PASSED} passés / ${TESTS_FAILED} échoués"

if [ "${TESTS_FAILED}" -eq 0 ]; then
    echo "- ✅ Test RÉUSSI — RTO mesuré : ${TOTAL_MINUTES} min"
    exit 0
else
    echo "- ❌ Test ÉCHOUÉ — investigation requise"
    exit 1
fi
