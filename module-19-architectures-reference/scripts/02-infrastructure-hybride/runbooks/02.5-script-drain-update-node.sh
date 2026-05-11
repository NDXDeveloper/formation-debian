#!/usr/bin/env bash
# =============================================================================
# Module 19 — Architectures de référence
# Section 19.2.5 — Procédures d'exploitation et runbooks
# Fichier : drain-update-node.sh — script associé au runbook RB-001
# Licence : CC BY 4.0
# =============================================================================
# Drain → upgrade → reboot conditionnel → uncordon d'un nœud Kubernetes.
# À utiliser dans le cadre du runbook RB-001 (mise à jour cluster) :
# itérer manuellement sur chaque nœud avec une pause de 5 minutes entre
# chaque passage pour vérification du monitoring.
#
# Usage :
#   ./drain-update-node.sh wk-1.k8s.internal.example.com
# =============================================================================
set -euo pipefail

NODE_NAME="${1:?Usage: $0 <node-fqdn>}"

echo "[1/5] Drain ${NODE_NAME} ..."
kubectl drain "${NODE_NAME}" \
    --ignore-daemonsets \
    --delete-emptydir-data \
    --grace-period=120 \
    --timeout=300s

echo "[2/5] apt upgrade sur ${NODE_NAME} (reboot conditionnel) ..."
ssh admin@"${NODE_NAME}" << 'EOF'
sudo apt update
sudo apt upgrade -y
if [ -f /var/run/reboot-required ]; then
    echo "REBOOT REQUIS"
    sudo reboot
fi
EOF

echo "[3/5] Attente du retour Ready (max 300s) ..."
kubectl wait --for=condition=Ready "node/${NODE_NAME}" --timeout=300s

echo "[4/5] Uncordon ${NODE_NAME} ..."
kubectl uncordon "${NODE_NAME}"

echo "[5/5] Vérification reschedule des pods (30s) ..."
sleep 30
kubectl get pods --all-namespaces -o wide | grep "${NODE_NAME}" || true

echo "OK ${NODE_NAME} — attendre 5 min avant le nœud suivant"
