# =============================================================================
# Module: vm-windows
# Reusable module for provisioning Windows VMs on Proxmox
# Used for: Flare-VM, MS Cloud VM, Windows detonation VM
# =============================================================================

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

variable "vm_name"        { type = string }
variable "vm_id"          { type = number }
variable "target_node"    { type = string }
variable "iso"            { type = string }
variable "cores"          { type = number  default = 4 }
variable "memory"         { type = number  default = 8192 }
variable "disk_size"      { type = string  default = "100G" }
variable "disk_storage"   { type = string }
variable "virtio_iso"     { type = string  default = "local:iso/virtio-win.iso" }
variable "vlan_tag"       { type = number }
variable "tags"           { type = list(string) default = [] }
variable "vga_memory"     { type = number  default = 32 }

resource "proxmox_vm_qemu" "windows_vm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.target_node
  iso         = var.iso
  os_type     = "win10"
  agent       = 1
  tags        = join(";", var.tags)

  cores   = var.cores
  sockets = 1
  memory  = var.memory
  cpu     = "host"

  # OS disk
  disk {
    slot    = 0
    size    = var.disk_size
    type    = "scsi"
    storage = var.disk_storage
    format  = "qcow2"
    cache   = "writeback"
    ssd     = 1
    discard = "on"
  }

  # VirtIO drivers ISO (required for Windows to see SCSI disk)
  disk {
    slot    = 1
    size    = "0"
    type    = "ide"
    storage = "local"
    iso     = var.virtio_iso
  }

  network {
    model  = "virtio"
    bridge = "vmbr${var.vlan_tag}"
    tag    = var.vlan_tag
  }

  vga {
    type   = "std"
    memory = var.vga_memory
  }

  # Enable QEMU guest agent (install via virtio-win in Windows)
  # TPM and Secure Boot disabled — forensic lab does not require them
  machine  = "pc"
  bios     = "ovmf"    # UEFI for modern Windows compatibility
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  lifecycle {
    # Windows VMs are configured manually post-ISO install
    ignore_changes = [
      network,
      disk,
      iso,
    ]
  }
}

output "vm_name" {
  value = proxmox_vm_qemu.windows_vm.name
}

output "vm_id" {
  value = proxmox_vm_qemu.windows_vm.vmid
}
