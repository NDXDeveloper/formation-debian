#!/usr/bin/env bash
# =============================================================================
# Module 14 — CI/CD et GitOps
# Section 14.4.5 — Gestion des secrets en GitOps (bonnes pratiques)
# Fichier : .git/hooks/pre-commit — vérifier que les .secret.yaml sont chiffrés
# Licence : CC BY 4.0
# =============================================================================
# Hook Git pre-commit qui rejette tout commit contenant un fichier
# *.secret.yaml NON chiffré (ni SOPS, ni SealedSecret). Première ligne
# de défense contre le commit accidentel d'un secret en clair.
#
# Installation :
#   cp 04.5-pre-commit-hook.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Compléter avec gitleaks ou detect-secrets pour détecter les patterns
# de tokens/clés/mots de passe dans tous les fichiers (pas juste *.secret.yaml).
# =============================================================================
set -euo pipefail

# `--diff-filter=AM` exclut les fichiers supprimés (D) ou seulement renommés
# pour éviter de tenter `grep` sur des chemins inexistants.
files=$(git diff --cached --name-only --diff-filter=AM | grep '\.secret\.yaml$' || true)

for file in $files; do
    if ! grep -q "^sops:" "$file" && ! grep -q "^kind: SealedSecret" "$file"; then
        echo "ERREUR : $file contient un secret non chiffré !" >&2
        echo "Chiffrez-le avec : sops --encrypt --in-place $file" >&2
        exit 1
    fi
done
