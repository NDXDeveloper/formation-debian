# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2 — Aperçu HCL : déclaration d'une ressource libvirt_domain
# Fichier : exemple HCL standalone (snippet illustratif, non-déployable seul)
# Licence : CC BY 4.0
# =============================================================================
# Aperçu du langage HCL pour une première intuition. Pour un déploiement
# complet, voir modules/02.2-debian-vm/.
# =============================================================================

# Déclarer une machine virtuelle Debian sur libvirt/KVM
resource "libvirt_domain" "webserver" {
  name   = "web01"
  memory = 2048
  vcpu   = 2

  disk {
    volume_id = libvirt_volume.debian_root.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
}
