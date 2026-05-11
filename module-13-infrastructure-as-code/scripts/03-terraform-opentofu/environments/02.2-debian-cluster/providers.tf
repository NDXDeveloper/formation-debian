# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : providers.tf (cluster multi-VM)
# Licence : CC BY 4.0
# =============================================================================

terraform {
  required_version = ">= 1.13.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}
