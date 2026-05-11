#!/usr/bin/env bash
#
# Nom         : 01.5-backup-postgresql.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.5 — Bonnes pratiques
# Source      : module-05-scripting-automatisation/01.5-bonnes-pratiques.md
# Description : Sauvegarde quotidienne de toutes les bases PostgreSQL avec rotation et
#               notification d'erreur.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# backup_postgresql.sh — Sauvegarde quotidienne des bases PostgreSQL
#
# Description :
#   Effectue un pg_dumpall compressé, nettoie les sauvegardes anciennes
#   et vérifie l'intégrité de l'archive produite.
#
# Usage :
#   backup_postgresql.sh [-v] [-n] [-r <jours>]
#
# Options :
#   -v            Mode verbeux
#   -n            Dry-run (simulation sans écriture)
#   -r <jours>    Rétention en jours (défaut : 30)
#
# Prérequis :
#   - pg_dumpall (paquet postgresql-client)
#   - gzip
#   - Accès PostgreSQL configuré via .pgpass ou pg_hba.conf
#
# Codes de retour :
#   0  Sauvegarde réussie
#   1  Erreur de configuration ou prérequis manquant
#   2  Échec de la sauvegarde
#   3  Échec de la vérification d'intégrité
#
# Auteur : Équipe Infrastructure
# Dernière modification : 2025-04-14
#

set -euo pipefail
