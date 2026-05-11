# =============================================================================
# Module 14 — CI/CD et GitOps
# Section 14.1.2 — Pipelines : conception et bonnes pratiques
# Fichier : Dockerfile multi-stage optimisé pour le cache de layers CI
# Licence : CC BY 4.0
# =============================================================================
# Pattern fondamental : placer les instructions stables (dépendances système)
# AVANT les instructions volatiles (code source). Le cache de layers Docker
# est invalidé à partir de la première instruction modifiée — ranger les
# couches par fréquence de changement maximise sa réutilisation entre builds.
# =============================================================================

# Les dépendances changent rarement → couche cachée
FROM debian:trixie-slim AS deps
WORKDIR /app
COPY requirements.txt .
# Versions des paquets système non épinglées : exemple pédagogique illustrant
# le multi-stage. En production, pinner les versions APT (`pkg=X.Y.Z`).
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3-pip \
    && pip install --no-cache-dir --break-system-packages -r requirements.txt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Le code change à chaque commit → dernière couche
FROM deps AS app
WORKDIR /app
COPY . .
CMD ["python3", "main.py"]
