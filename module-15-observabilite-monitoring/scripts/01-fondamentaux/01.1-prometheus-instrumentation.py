#!/usr/bin/env python3
# =============================================================================
# Module 15 — Observabilité et monitoring
# Section 15.2.2 — PromQL et métriques custom
# Fichier : exemple d'instrumentation prometheus_client en Python
# Licence : CC BY 4.0
# =============================================================================
# Démontre les 3 types fondamentaux :
#   - Counter   : monotone, augmente uniquement (taux via rate())
#   - Gauge     : valeur instantanée, peut monter/descendre
#   - Histogram : distribution avec buckets (latence, taille de payload)
#
# `time.monotonic()` est préférable à `time.time()` pour mesurer une durée :
# il est insensible aux ajustements de l'horloge système (NTP, DST).
#
# Installation : apt install python3-prometheus-client
#                ou pip install prometheus_client (dans un venv)
# =============================================================================

import time
from prometheus_client import Counter, Gauge, Histogram, start_http_server

# Définition des métriques
REQUEST_COUNT = Counter(
    'myapp_http_requests_total',
    'Total HTTP requests processed',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'myapp_http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint'],
    buckets=[0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]
)

ACTIVE_CONNECTIONS = Gauge(
    'myapp_active_connections',
    'Number of active connections',
    ['pool']
)

QUEUE_SIZE = Gauge(
    'myapp_queue_size',
    'Current size of the processing queue'
)


def handle_request(method, endpoint):
    """Exemple d'instrumentation manuelle d'une requête HTTP."""
    start = time.monotonic()
    try:
        # ... traitement de la requête ...
        status = "200"
    except Exception:
        status = "500"
    finally:
        duration = time.monotonic() - start
        REQUEST_COUNT.labels(method=method, endpoint=endpoint, status=status).inc()
        REQUEST_LATENCY.labels(method=method, endpoint=endpoint).observe(duration)


# Utilisation du décorateur pour simplifier la mesure de durée
@REQUEST_LATENCY.labels(method='GET', endpoint='/api/data').time()
def get_data():
    # ... logique métier ...
    pass


if __name__ == '__main__':
    # Démarrage du serveur HTTP pour exposer /metrics
    start_http_server(8000)  # http://localhost:8000/metrics
    # ... boucle principale de l'application ...
    while True:
        time.sleep(1)
