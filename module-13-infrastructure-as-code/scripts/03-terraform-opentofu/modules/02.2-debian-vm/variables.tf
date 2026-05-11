# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : variables.tf (déclarations de variables d'entrée)
# Licence : CC BY 4.0
# =============================================================================

variable "vm_name" {
  description = "Nom de la machine virtuelle"
  type        = string
  default     = "debian-test"
}

variable "memory" {
  description = "Mémoire en Mo"
  type        = number
  default     = 1024
}

variable "vcpu" {
  description = "Nombre de vCPU"
  type        = number
  default     = 1
}

variable "disk_size_gb" {
  description = "Taille du disque en Go"
  type        = number
  default     = 10
}

variable "ssh_public_key_path" {
  description = "Chemin vers la clé publique SSH"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "network_address" {
  description = "Adresse IP statique de la VM (CIDR)"
  type        = string
  default     = "192.168.122.100/24"
}

variable "network_gateway" {
  description = "Passerelle par défaut"
  type        = string
  default     = "192.168.122.1"
}
