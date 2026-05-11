# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : variables.tf (cluster multi-VM)
# Licence : CC BY 4.0
# =============================================================================

variable "cluster_name" {
  description = "Nom du cluster"
  type        = string
  default     = "lab"
}

variable "domain" {
  description = "Domaine DNS"
  type        = string
  default     = "lab.local"
}

variable "ssh_public_key_path" {
  description = "Chemin vers la clé publique SSH"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "base_network" {
  description = "Réseau de base (trois premiers octets)"
  type        = string
  default     = "10.10.10"
}

variable "servers" {
  description = "Définition des serveurs du cluster"
  type = map(object({
    role      = string
    memory    = number
    vcpu      = number
    disk_gb   = number
    ip_offset = number
  }))
  default = {
    "web01" = { role = "webservers", memory = 1024, vcpu = 1, disk_gb = 10, ip_offset = 10 }
    "web02" = { role = "webservers", memory = 1024, vcpu = 1, disk_gb = 10, ip_offset = 11 }
    "db01"  = { role = "dbservers", memory = 2048, vcpu = 2, disk_gb = 20, ip_offset = 20 }
    "mon01" = { role = "monitoring", memory = 1024, vcpu = 1, disk_gb = 15, ip_offset = 30 }
  }
}
