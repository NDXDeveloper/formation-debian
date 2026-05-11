# =============================================================================
# Module 19 — Architectures de référence
# Section 19.1.1 — Configuration poste développeur Debian
# Fichier : ~/.aliases — alias productifs cloud-native
# Licence : CC BY 4.0
# =============================================================================
# À sourcer depuis ~/.bashrc ou ~/.zshrc :
#   [ -f ~/.aliases ] && source ~/.aliases
# =============================================================================
# shellcheck shell=bash

# --- Navigation et système ---
alias ..="cd .."
alias ...="cd ../.."
alias ll="ls -alFh --color=auto"
alias df="df -h"
alias free="free -h"
alias ports="ss -tulnp"

# --- Git ---
alias gs="git status"
alias gd="git diff"
alias gl="git log --oneline --graph --decorate -20"
alias gco="git checkout"
alias gcm="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gb="git branch"

# --- Kubernetes (k = kubectl) ---
alias k="kubectl"
alias kg="kubectl get"
alias kgp="kubectl get pods"
alias kgs="kubectl get services"
alias kgd="kubectl get deployments"
alias kd="kubectl describe"
alias kl="kubectl logs"
alias klf="kubectl logs -f"
alias kex="kubectl exec -it"
alias kctx="kubectx"
alias kns="kubens"

# --- Docker ---
alias d="docker"
alias dc="docker compose"
alias dps="docker ps"
alias dpsa="docker ps -a"
alias di="docker images"
alias dprune="docker system prune -af"

# --- Terraform / OpenTofu ---
alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"
alias tfd="terraform destroy"
