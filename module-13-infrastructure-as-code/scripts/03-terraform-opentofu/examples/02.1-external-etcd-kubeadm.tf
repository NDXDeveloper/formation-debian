# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2 — Patterns d'exemple
# Fichier : exemple HCL d'une data source ipify (via http)
# Licence : CC BY 4.0
# =============================================================================
# Démonstration d'une data source HTTP qui interroge une API externe au
# moment du plan/apply pour récupérer l'IP publique du runner.
# Utile pour générer des règles de pare-feu ou des entrées DNS.
# =============================================================================

terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

data "http" "my_public_ip" {
  url = "https://api.ipify.org?format=json"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  my_ip = jsondecode(data.http.my_public_ip.response_body).ip
}

output "public_ip" {
  description = "IP publique détectée du nœud Terraform"
  value       = local.my_ip
}
