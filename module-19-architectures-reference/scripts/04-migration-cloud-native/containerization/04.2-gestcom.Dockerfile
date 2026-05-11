# =============================================================================
# Module 19 — Architectures de référence
# Section 19.4.2 — Conteneurisation microservices (GestCom)
# Fichier : Dockerfile multi-stage PHP/Symfony → Debian Trixie
# Licence : CC BY 4.0
# =============================================================================
# Migration de l'application legacy GestCom (Symfony, PHP 8.4) vers une
# image OCI conteneurisée. Multi-stage build optimisé :
#   1. composer-deps  : install dépendances PHP (cache)
#   2. assets-build   : compilation assets front (Webpack)
#   3. production     : image finale Debian Trixie + Apache + PHP 8.4
#
# Notes :
#   - PHP 8.4 : active support jusqu'au 31 décembre 2026, security jusqu'en
#     décembre 2028 (cycle 2 ans active + 2 ans security depuis mars 2024)
#   - wkhtmltopdf : upstream archivé en 2023, dette technique connue —
#     migrer vers WeasyPrint ou Gotenberg pour les nouveaux modules PDF
#   - Apache écoute sur 8080 (USER non-root ne peut pas binder < 1024)
#
# Validation : hadolint Dockerfile
# Build : docker build -t gestcom:dev .
# =============================================================================

# ══════════════════════════════════════════════════════════════
# Stage 1 : Installation des dépendances PHP (Composer)
# ══════════════════════════════════════════════════════════════
FROM composer:2 AS composer-deps

WORKDIR /app

# Copier uniquement les fichiers de dépendances (cache de couche Docker)
COPY composer.json composer.lock symfony.lock ./

# Installer les dépendances de production (sans les dev)
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --no-interaction

# Copier le reste du code pour l'autoloader optimisé
COPY . .

RUN composer dump-autoload --optimize --classmap-authoritative --no-dev

# ══════════════════════════════════════════════════════════════
# Stage 2 : Build des assets front-end
# ══════════════════════════════════════════════════════════════
FROM node:22-trixie-slim AS assets-build

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production=false

COPY webpack.config.js ./
COPY assets/ assets/

RUN yarn build

# ══════════════════════════════════════════════════════════════
# Stage 3 : Image de production
# ══════════════════════════════════════════════════════════════
FROM debian:trixie-slim AS production

# Métadonnées OCI
LABEL org.opencontainers.image.title="GestCom" \
      org.opencontainers.image.description="Application de gestion commerciale" \
      org.opencontainers.image.vendor="Entreprise" \
      org.opencontainers.image.source="https://gitlab.apps.internal.example.com/equipe-commerce/gestcom"

# Éviter les interactions pendant l'installation
ENV DEBIAN_FRONTEND=noninteractive

# Installation de PHP 8.4, Apache et des extensions nécessaires
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    libapache2-mod-php8.4 \
    php8.4 \
    php8.4-mysql \
    php8.4-pgsql \
    php8.4-redis \
    php8.4-gd \
    php8.4-intl \
    php8.4-xml \
    php8.4-mbstring \
    php8.4-zip \
    php8.4-curl \
    php8.4-soap \
    php8.4-apcu \
    wkhtmltopdf \
    fontconfig \
    fonts-dejavu-core \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod rewrite headers expires

# Configuration Apache pour un environnement conteneurisé
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

COPY docker/apache/gestcom.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php/php-production.ini /etc/php/8.4/apache2/conf.d/99-production.ini

# Utilisateur non-root pour l'exécution
RUN groupadd -r gestcom && useradd -r -g gestcom -d /app gestcom \
    && mkdir -p /app /var/run/apache2 /var/lock/apache2 /var/log/apache2 \
    && chown -R gestcom:gestcom /app /var/run/apache2 /var/lock/apache2 /var/log/apache2

WORKDIR /app

# Copier le code applicatif et les dépendances depuis les stages précédents
COPY --from=composer-deps --chown=gestcom:gestcom /app/vendor/ vendor/
COPY --from=assets-build /app/public/build/ public/build/
COPY --chown=gestcom:gestcom . .

# Supprimer les fichiers non nécessaires en production
RUN rm -rf \
    docker/ \
    tests/ \
    .git/ \
    .env.test \
    phpunit.xml.dist \
    webpack.config.js \
    assets/ \
    node_modules/

# Préchauffer le cache Symfony
RUN php bin/console cache:warmup --env=prod --no-debug

# Créer le répertoire uploads (sera monté en PVC en production)
RUN mkdir -p /app/uploads && chown gestcom:gestcom /app/uploads

# Ports
EXPOSE 8080

# Rediriger les logs Apache vers stdout/stderr
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log

# Apache doit écouter sur 8080 (non-root ne peut pas utiliser 80)
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf

# Health check intégré
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

USER gestcom

CMD ["apache2ctl", "-D", "FOREGROUND"]
