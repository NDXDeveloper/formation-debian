# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.3 — État (state) et backends
# Fichier : backend S3 moderne (Terraform 1.10+) avec verrouillage natif
# Licence : CC BY 4.0
# =============================================================================
# La configuration `use_lockfile = true` (Terraform 1.10+) remplace
# avantageusement la table DynamoDB historique pour le verrouillage.
# =============================================================================

terraform {
  required_version = ">= 1.13.0"

  backend "s3" {
    bucket       = "mon-organisation-terraform-state"
    key          = "infrastructure/lab-cluster/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.0"
    }
  }
}
