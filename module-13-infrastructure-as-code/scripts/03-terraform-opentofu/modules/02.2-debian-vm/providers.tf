# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : providers.tf (configuration des providers et contraintes de version)
# Licence : CC BY 4.0
# =============================================================================
# Configuration du provider libvirt pour le déploiement de VMs Debian
# sur un hyperviseur KVM local. La branche 0.8.x reste stable et
# largement déployée. La 0.9.x introduit des breaking changes
# (cf. discussion #1194 sur dmacvicar/terraform-provider-libvirt).
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
  # Connexion à l'hyperviseur local
  uri = "qemu:///system"
}
