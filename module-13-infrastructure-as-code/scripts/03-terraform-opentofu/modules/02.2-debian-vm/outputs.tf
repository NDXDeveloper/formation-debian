# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : outputs.tf (sorties exposées par le module)
# Licence : CC BY 4.0
# =============================================================================

output "vm_ip" {
  description = "Adresse IP de la VM"
  value       = libvirt_domain.vm.network_interface[0].addresses[0]
}

output "vm_name" {
  description = "Nom de la VM"
  value       = libvirt_domain.vm.name
}

output "ssh_command" {
  description = "Commande SSH pour se connecter"
  value       = "ssh debian@${libvirt_domain.vm.network_interface[0].addresses[0]}"
}
