# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : outputs.tf (cluster + génération inventaire Ansible)
# Licence : CC BY 4.0
# =============================================================================
# Pont Terraform → Ansible : `ansible_inventory` peut être redirigé vers
# un fichier d'inventaire INI consommé par ansible-playbook.
# =============================================================================

output "server_ips" {
  description = "Adresses IP de tous les serveurs"
  value = {
    for name, vm in libvirt_domain.server :
    name => vm.network_interface[0].addresses[0]
  }
}

output "ssh_commands" {
  description = "Commandes SSH pour chaque serveur"
  value = {
    for name, vm in libvirt_domain.server :
    name => "ssh debian@${vm.network_interface[0].addresses[0]}"
  }
}

output "servers_by_role" {
  description = "Serveurs groupés par rôle"
  value = {
    for role in distinct([for s in var.servers : s.role]) :
    role => [
      for name, vm in libvirt_domain.server :
      {
        name = name
        ip   = vm.network_interface[0].addresses[0]
      }
      if var.servers[name].role == role
    ]
  }
}

# Sortie au format compatible avec un inventaire Ansible
# Le champ `role` de chaque serveur est utilisé directement comme nom de groupe Ansible,
# c'est pourquoi il est écrit au pluriel dans var.servers (webservers, dbservers...).
output "ansible_inventory" {
  description = "Inventaire Ansible au format INI"
  value = join("\n", concat(
    ["# Inventaire généré par Terraform", ""],
    [for role in distinct([for s in var.servers : s.role]) :
      join("\n", concat(
        ["[${role}]"],
        [for name, vm in libvirt_domain.server :
          "${name} ansible_host=${vm.network_interface[0].addresses[0]} ansible_user=debian"
          if var.servers[name].role == role
        ],
        [""]
      ))
    ]
  ))
}
