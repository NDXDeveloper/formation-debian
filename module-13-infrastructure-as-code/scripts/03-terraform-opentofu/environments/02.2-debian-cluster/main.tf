# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.2 — Installation sur Debian et premiers déploiements
# Fichier : main.tf (cluster multi-VM avec for_each)
# Licence : CC BY 4.0
# =============================================================================
# Démontre l'usage de for_each pour itérer sur var.servers.
# L'avantage de for_each sur count : les clés de map sont des identifiants
# stables — l'ajout d'un serveur ne réordonne pas les ressources existantes.
# =============================================================================

# --- Image de base ---
resource "libvirt_volume" "debian_base" {
  name   = "${var.cluster_name}-debian-13-base.qcow2"
  pool   = "default"
  source = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  format = "qcow2"

  lifecycle {
    ignore_changes = [source]
  }
}

# --- Volumes (un par serveur) ---
resource "libvirt_volume" "root" {
  for_each = var.servers

  name           = "${var.cluster_name}-${each.key}-root.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.debian_base.id
  size           = each.value.disk_gb * 1024 * 1024 * 1024
  format         = "qcow2"
}

# --- Cloud-init (un par serveur) ---
resource "libvirt_cloudinit_disk" "init" {
  for_each = var.servers

  name = "${var.cluster_name}-${each.key}-cloudinit.iso"
  pool = "default"

  user_data = templatefile("${path.module}/templates/cloud-init-userdata.yml.tftpl", {
    hostname       = each.key
    fqdn           = local.server_fqdns[each.key]
    ssh_public_key = local.ssh_public_key
    role           = each.value.role
    hosts_entries  = local.etc_hosts_entries
  })

  network_config = templatefile("${path.module}/templates/cloud-init-network.yml.tftpl", {
    address = "${local.server_ips[each.key]}/24"
    gateway = "${var.base_network}.1"
  })
}

# --- Machines virtuelles ---
resource "libvirt_domain" "server" {
  for_each = var.servers

  name   = "${var.cluster_name}-${each.key}"
  memory = each.value.memory
  vcpu   = each.value.vcpu

  cloudinit = libvirt_cloudinit_disk.init[each.key].id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.root[each.key].id
    scsi      = true
  }

  network_interface {
    network_id     = libvirt_network.cluster.id
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

  depends_on = [libvirt_network.cluster]
}
