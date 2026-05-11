# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.3 — État (state) et backends
# Fichier : backend Consul (on-premise, multi-DC)
# Licence : CC BY 4.0
# =============================================================================
# Le backend Consul stocke le state dans le KV store. Le verrouillage
# utilise les sessions Consul. Avantage : 100 % on-premise, réplication
# multi-datacenter native.
#
# Le token ACL doit être fourni via la variable d'environnement
# CONSUL_HTTP_TOKEN ou via -backend-config.
# =============================================================================

terraform {
  backend "consul" {
    address = "consul.example.com:8500"
    scheme  = "https"
    path    = "terraform/infrastructure/lab-cluster"
    lock    = true

    # Authentification par token ACL (à fournir via CONSUL_HTTP_TOKEN)
    access_token = "consul-acl-token"
  }
}
