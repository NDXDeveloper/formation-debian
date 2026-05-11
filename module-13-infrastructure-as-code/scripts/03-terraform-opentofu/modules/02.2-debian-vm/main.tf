# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : main.tf (ressources principales)
# Licence : CC BY 4.0
# =============================================================================
# Provisionnement d'une VM Debian 13 avec cloud-init :
#   1. Téléchargement de l'image cloud Debian de base
#   2. Clonage redimensionné pour la VM
#   3. Création du disque cloud-init (user-data + network-config)
#   4. Création du domaine libvirt avec attente de bail DHCP
# =============================================================================

# --- Clé SSH ---
locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

# --- Image de base Debian ---
resource "libvirt_volume" "debian_base" {
  name   = "debian-13-base.qcow2"
  pool   = "default"
  source = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  format = "qcow2"

  lifecycle {
    # Ne pas retélécharger l'image si elle existe déjà
    ignore_changes = [source]
  }
}

# --- Volume de la VM (clone redimensionné) ---
resource "libvirt_volume" "root" {
  name           = "${var.vm_name}-root.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.debian_base.id
  size           = var.disk_size_gb * 1024 * 1024 * 1024
  format         = "qcow2"
}

# --- Cloud-init ---
resource "libvirt_cloudinit_disk" "init" {
  name = "${var.vm_name}-cloudinit.iso"
  pool = "default"

  user_data = templatefile("${path.module}/templates/cloud-init-userdata.yml.tftpl", {
    hostname       = var.vm_name
    ssh_public_key = local.ssh_public_key
  })

  network_config = templatefile("${path.module}/templates/cloud-init-network.yml.tftpl", {
    address = var.network_address
    gateway = var.network_gateway
  })
}

# --- Machine virtuelle ---
resource "libvirt_domain" "vm" {
  name   = var.vm_name
  memory = var.memory
  vcpu   = var.vcpu

  cloudinit = libvirt_cloudinit_disk.init.id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.root.id
    scsi      = true
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }

  # Attendre que cloud-init se termine. Synchronisation, pas configuration.
  provisioner "remote-exec" {
    inline = ["cloud-init status --wait > /dev/null 2>&1"]

    connection {
      type        = "ssh"
      user        = "debian"
      private_key = file(pathexpand(replace(var.ssh_public_key_path, ".pub", "")))
      host        = self.network_interface[0].addresses[0]
      timeout     = "5m"
    }
  }
}
