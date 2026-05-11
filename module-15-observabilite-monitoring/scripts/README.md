# Scripts du Module 15 — Observabilité et monitoring

Cette arborescence regroupe les **configurations Prometheus / Grafana /  
Loki / Tempo / OTel Collector / Jaeger** complètes extraites du Module 15  
et organisées par stack. Chaque fichier porte un en-tête normalisé  
identifiant sa section d'origine, et a été validé syntaxiquement dans un  
conteneur Debian 13.  

## Convention de nommage

```
<XX.Y>-<nom-court-kebab>.<ext>
```

| Préfixe | Section du module | Contenu |
|---------|-------------------|---------|
| `01.1-*` | 15.1.1 — Métriques, logs, traces | Format d'exposition, instrumentation |
| `02.1-*` | 15.2.1 — Prometheus architecture | prometheus.yml, systemd, file_sd |
| `02.2-*` | 15.2.2 — PromQL et métriques custom | Recording rules SLI |
| `02.3-*` | 15.2.3 — AlertManager | Alerting rules, alertmanager.yml, tests promtool |
| `02.4-*` | 15.2.4 — Grafana dashboards | provisioning, dashboards JSON, reverse proxy |
| `02.5-*` | 15.2.5 — node_exporter | systemd unit, textfile collector |
| `03.2-*` | 15.3.2 — Loki + Promtail/Alloy | loki-config, promtail-config, alloy |
| `03.3-*` | 15.3.3 — Multi-cluster | Buffering Fluent Bit |
| `03.4-*` | 15.3.4 — Intégration journald | journald.conf, fluent-bit |
| `04.2-*` | 15.4.2 — Jaeger | jaeger-config (v2.17+), UI config |
| `04.3-*` | 15.4.3 — OpenTelemetry | otel-collector.yaml, tempo-config |

## Arborescence

```
scripts/
├── README.md                                     # Ce fichier
├── 01-fondamentaux/
│   ├── 01.1-prometheus-instrumentation.py       # Counter/Gauge/Histogram en Python
│   └── 01.1-exposition-format.txt               # Format texte /metrics
├── 02-prometheus/
│   ├── 02.1-prometheus-base.yml                 # /etc/prometheus/prometheus.yml
│   ├── 02.1-prometheus.service                  # systemd unit Prometheus 3.x
│   ├── 02.3-alertmanager.yml                    # /etc/alertmanager/alertmanager.yml
│   ├── 02.3-alertmanager.service                # systemd unit AlertManager
│   ├── rules/
│   │   ├── 02.2-recording-rules-sli.yml         # SLI sur fenêtres multiples
│   │   ├── 02.3-alerting-burn-rate-slo.yml      # Burn rate multi-fenêtres
│   │   ├── 02.3-alerting-node-infrastructure.yml # Cause-pointing infrastructure
│   │   └── 02.3-tests-alerts-promtool.yml       # Tests unitaires des alertes
│   └── targets/
│       └── 02.1-targets-node-servers.yml        # file_sd_configs nodes
├── 03-grafana/
│   ├── 02.4-grafana.ini.snippet                 # Extraits production
│   ├── 02.4-nginx-grafana-vhost.conf            # Reverse proxy Nginx + WS
│   ├── 02.4-add-deploy-annotation.sh            # Annotation déploiement via API
│   ├── dashboards/
│   │   ├── 02.4-service-overview-red-slo.json   # Dashboard RED + SLO
│   │   └── 02.4-service-overview-red-slo.meta.yaml # Métadonnées sidecar
│   └── provisioning/
│       ├── 02.4-datasources.yaml                # Prom + Loki + Tempo (corrélation)
│       └── 02.4-dashboards.yaml                 # Provider de dashboards
├── 04-logs/
│   ├── 03.2-loki-config.yaml                    # Loki monolithique TSDB
│   ├── 03.2-promtail-config.yml                 # Promtail (EOL — gardé pour migration)
│   ├── 02.3-alloy-runner-logs.alloy             # Alloy (successeur Promtail)
│   ├── 03.3-fluent-bit-buffer-loki.conf         # Buffer multi-cluster
│   ├── 03.4-fluent-bit-journald.conf            # Lecture journald
│   └── 03.4-journald.conf                       # /etc/systemd/journald.conf
├── 05-traces/
│   ├── 04.2-jaeger-config.yml                   # Jaeger v2.17+ (healthcheckv2)
│   ├── 04.2-jaeger-ui-config.json               # UI config Jaeger
│   ├── 04.3-tempo-config.yaml                   # Tempo + metrics_generator
│   └── 04.3-otel-collector.yaml                 # Collector v0.151+ (3 pipelines)
└── 06-exporters/
    ├── 02.1-blackbox-exporter.yml               # Probes HTTP/TCP/ICMP/DNS
    ├── 02.5-node-exporter.service               # systemd unit hardenée
    └── 02.5-node-exporter-textfile-example.sh   # Métriques custom APT
```

## Index tabulé

### Section 15.1 — Fondamentaux

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `01-fondamentaux/01.1-prometheus-instrumentation.py` | Counter + Gauge + Histogram + serveur HTTP | python AST + import |
| `01-fondamentaux/01.1-exposition-format.txt` | Format texte attendu sur `/metrics` | inspection manuelle |

### Section 15.2 — Prometheus / AlertManager / Grafana

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `02-prometheus/02.1-prometheus-base.yml` | Config Prometheus avec relabel blackbox | promtool check config |
| `02-prometheus/02.1-prometheus.service` | systemd hardené (sans flags consoles obsolètes) | systemd-analyze (référence) |
| `02-prometheus/targets/02.1-targets-node-servers.yml` | file_sd_configs nodes par rôle | yaml.safe_load |
| `02-prometheus/rules/02.2-recording-rules-sli.yml` | 8 SLI pré-calculés sur 5 fenêtres | promtool check rules (8 OK) |
| `02-prometheus/rules/02.3-alerting-burn-rate-slo.yml` | 3 burn rates (critical/warning/info) | promtool check rules (3 OK) |
| `02-prometheus/rules/02.3-alerting-node-infrastructure.yml` | 8 alertes cause-pointing (disque/RAM/réseau/TLS) | promtool check rules (8 OK) |
| `02-prometheus/rules/02.3-tests-alerts-promtool.yml` | Test unitaire NodeDiskSpaceCritical | promtool test rules (SUCCESS) |
| `02-prometheus/02.3-alertmanager.yml` | Routes 4 niveaux + 4 receivers + 2 inhibit | amtool check-config |
| `02-prometheus/02.3-alertmanager.service` | systemd avec mode cluster | systemd-analyze (référence) |
| `03-grafana/02.4-grafana.ini.snippet` | Sections production (server/auth/security) | inspection (format INI) |
| `03-grafana/02.4-nginx-grafana-vhost.conf` | Reverse proxy avec WebSocket | nginx -t (référence) |
| `03-grafana/02.4-add-deploy-annotation.sh` | Push annotation via API Grafana | shellcheck |
| `03-grafana/dashboards/02.4-service-overview-red-slo.json` | Dashboard RED + SLO (5 panels, variable $service) | jq + jq -e .title |
| `03-grafana/dashboards/02.4-service-overview-red-slo.meta.yaml` | Métadonnées sidecar du dashboard | yamllint |
| `03-grafana/provisioning/02.4-datasources.yaml` | Prom + Loki + Tempo avec corrélations croisées | yamllint |
| `03-grafana/provisioning/02.4-dashboards.yaml` | Provider file scanning `/var/lib/grafana/dashboards` | yamllint |
| `06-exporters/02.5-node-exporter.service` | systemd avec CAP_DAC_READ_SEARCH + hardening | systemd-analyze (référence) |
| `06-exporters/02.5-node-exporter-textfile-example.sh` | Métriques APT pending via textfile collector | shellcheck |
| `06-exporters/02.1-blackbox-exporter.yml` | Modules HTTP/TCP/ICMP/DNS/SSH | yamllint |

### Section 15.3 — Logs

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `04-logs/03.2-loki-config.yaml` | Loki 3.x mode `all` (monolithique) avec TSDB | loki -verify-config |
| `04-logs/03.2-promtail-config.yml` | Promtail journald + Nginx (EOL mars 2026) | promtail -check-syntax |
| `04-logs/02.3-alloy-runner-logs.alloy` | Alloy/River : journald → Loki | inspection (River) |
| `04-logs/03.3-fluent-bit-buffer-loki.conf` | Buffer disque multi-cluster | inspection (INI Fluent Bit) |
| `04-logs/03.4-fluent-bit-journald.conf` | Plugin systemd avec Strip_Underscores | inspection (INI Fluent Bit) |
| `04-logs/03.4-journald.conf` | journald production (Storage=persistent, ForwardToSyslog=no) | inspection (INI systemd) |

### Section 15.4 — Traces

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `05-traces/04.2-jaeger-config.yml` | Jaeger v2.17+ (healthcheckv2 + badger.directories) | jaeger startup test (HTTP 200) |
| `05-traces/04.2-jaeger-ui-config.json` | UI config Jaeger | jq -e |
| `05-traces/04.3-tempo-config.yaml` | Tempo + metrics_generator (spanmetrics + service_graphs) | yamllint + python yaml |
| `05-traces/04.3-otel-collector.yaml` | Collector v0.151+ : 3 pipelines, telemetry.metrics.readers | otelcol-contrib validate |

## Notes importantes

### Versions Prometheus 3.x

L'unité systemd `02-prometheus/02.1-prometheus.service` **n'inclut pas**  
les flags `--web.console.templates` et `--web.console.libraries` car les  
répertoires `consoles/` et `console_libraries/` ne sont plus distribués  
depuis Prometheus 3.0.0 (l'UI moderne passe intégralement par Grafana).  

### Versions Jaeger v2.17+

Le fichier `05-traces/04.2-jaeger-config.yml` utilise la nouvelle syntaxe :
- Extension `healthcheckv2` (anciennement `health_check`) avec sous-protocoles
  `http:` et `grpc:` obligatoires
- Backend badger : `directories.keys/values` (anciennement `directory_key/value`)
  et `ttl.spans` (anciennement `span_store_ttl`)

### Versions OTel Collector v0.123+

Le fichier `05-traces/04.3-otel-collector.yaml` utilise la nouvelle syntaxe
`service.telemetry.metrics.readers` (la clé `address` raccourci historique
est rejetée en v0.123+ avec « 'migration.MetricsConfigV030' has invalid  
keys: address »).  

### Promtail EOL

Le fichier `04-logs/03.2-promtail-config.yml` est conservé pour les  
déploiements existants. Pour de **nouvelles installations en 2026**,  
utiliser `04-logs/02.3-alloy-runner-logs.alloy` (Grafana Alloy, syntaxe  
River). Migration : `alloy convert --source-format=promtail`.  

### Secrets et placeholders

Tous les secrets sont des placeholders ou des références :

- AlertManager : `*_password_file`, `*_key_file` (jamais en clair dans le YAML)
- Grafana : `${GRAFANA_ADMIN_PASSWORD}` via systemd EnvironmentFile
- Tempo / MinIO : `${MINIO_ACCESS_KEY}` / `${MINIO_SECRET_KEY}` (démarrer
  avec `-config.expand-env=true`)
- Pipeline Grafana annotation : variables d'environnement strictement requises

### Dashboards Grafana

Le format JSON Grafana ne supporte pas les commentaires natifs. Le  
fichier dashboard `02.4-service-overview-red-slo.json` documente sa  
provenance via la clé `description` du JSON, et un sidecar  
`02.4-service-overview-red-slo.meta.yaml` détaille les variables, panels
et prérequis (recording rules à charger, métriques à exposer).

## Prérequis d'utilisation

- **Prometheus** : binaire upstream v3.5.3 LTS depuis github.com/prometheus
- **AlertManager** : binaire upstream v0.32.1
- **node_exporter** : binaire upstream v1.11.1 ou paquet APT `prometheus-node-exporter`
- **Grafana** : dépôt APT officiel `apt.grafana.com` (paquet `grafana`)
- **Loki + Promtail** : binaires upstream v3.7.1 (Loki) et v3.2.1 (Promtail, EOL)
- **Grafana Alloy** : binaire upstream v1.16+ (recommandé vs Promtail)
- **OTel Collector** : `.deb` upstream v0.151.0 (distribution `contrib`)
- **Tempo** : `.deb` upstream v2.10.5
- **Jaeger** : tarball upstream v2.17.0

## Licence

CC BY 4.0 — Attribution 4.0 International
