# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : network.tf (réseau dédié au cluster + DNS local)
# Licence : CC BY 4.0
# =============================================================================
# Réseau libvirt avec NAT, DNS local-only et IP statiques (DHCP désactivé).
# Les entrées DNS sont générées dynamiquement via dynamic "hosts".
# =============================================================================

resource "libvirt_network" "cluster" {
  name      = "${var.cluster_name}-network"
  mode      = "nat"
  domain    = var.domain
  autostart = true

  addresses = ["${var.base_network}.0/24"]

  dns {
    enabled    = true
    local_only = true

    dynamic "hosts" {
      for_each = var.servers
      content {
        hostname = hosts.key
        ip       = local.server_ips[hosts.key]
      }
    }
  }

  dhcp {
    enabled = false
  }
}
