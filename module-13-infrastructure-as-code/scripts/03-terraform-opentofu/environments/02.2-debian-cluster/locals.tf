# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : locals.tf (calculs et regroupements dérivés)
# Licence : CC BY 4.0
# =============================================================================

locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))

  # Construire les adresses IP complètes
  server_ips = {
    for name, spec in var.servers :
    name => "${var.base_network}.${spec.ip_offset}"
  }

  # Construire les FQDNs
  server_fqdns = {
    for name, spec in var.servers :
    name => "${name}.${var.domain}"
  }

  # Grouper les serveurs par rôle
  servers_by_role = {
    for role in distinct([for s in var.servers : s.role]) :
    role => {
      for name, spec in var.servers :
      name => spec
      if spec.role == role
    }
  }

  # Entrées /etc/hosts pour toutes les VMs
  etc_hosts_entries = [
    for name, spec in var.servers :
    "${local.server_ips[name]}  ${local.server_fqdns[name]}  ${name}"
  ]
}
