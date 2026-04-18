#!/usr/bin/env bash
# =============================================================================
# build-templates.sh — Build Proxmox cloud-init VM templates
# Run this on the Proxmox host BEFORE running terraform apply
# =============================================================================
# Usage: ssh root@10.0.10.1 'bash -s' < scripts/build-templates.sh
# =============================================================================

set -euo pipefail

STORAGE="local-lvm"
ISO_STORAGE="local"
NODE=$(hostname)

log() { echo "[$(date +%H:%M:%S)] $*"; }

# ── Ubuntu 22.04 template ─────────────────────────────────────────────────────
log "Building Ubuntu 22.04 cloud-init template..."
UBUNTU_IMG="/tmp/ubuntu-22.04-server-cloudimg-amd64.img"

if [[ ! -f "$UBUNTU_IMG" ]]; then
  wget -q "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" \
    -O "$UBUNTU_IMG"
fi

qm create 9000 \
  --name ubuntu-2204-cloudinit-template \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket \
  --vga serial0 \
  --agent enabled=1

qm importdisk 9000 "$UBUNTU_IMG" "$STORAGE"
qm set 9000 \
  --scsihw virtio-scsi-pci \
  --scsi0 "${STORAGE}:vm-9000-disk-0" \
  --ide2 "${STORAGE}:cloudinit" \
  --boot c \
  --bootdisk scsi0 \
  --ipconfig0 ip=dhcp \
  --ciupgrade 1

qm template 9000
log "Ubuntu 22.04 template created: ID 9000"

# ── Ubuntu 20.04 template (CAPE requirement) ─────────────────────────────────
log "Building Ubuntu 20.04 cloud-init template..."
UBUNTU20_IMG="/tmp/ubuntu-20.04-server-cloudimg-amd64.img"

if [[ ! -f "$UBUNTU20_IMG" ]]; then
  wget -q "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img" \
    -O "$UBUNTU20_IMG"
fi

qm create 9001 \
  --name ubuntu-2004-cloudinit-template \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket \
  --vga serial0 \
  --agent enabled=1

qm importdisk 9001 "$UBUNTU20_IMG" "$STORAGE"
qm set 9001 \
  --scsihw virtio-scsi-pci \
  --scsi0 "${STORAGE}:vm-9001-disk-0" \
  --ide2 "${STORAGE}:cloudinit" \
  --boot c \
  --bootdisk scsi0 \
  --ipconfig0 ip=dhcp

qm template 9001
log "Ubuntu 20.04 template created: ID 9001"

# ── Debian 12 template ────────────────────────────────────────────────────────
log "Building Debian 12 cloud-init template..."
DEBIAN_IMG="/tmp/debian-12-generic-amd64.qcow2"

if [[ ! -f "$DEBIAN_IMG" ]]; then
  wget -q "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2" \
    -O "$DEBIAN_IMG"
fi

qm create 9002 \
  --name debian-12-cloudinit-template \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket \
  --vga serial0 \
  --agent enabled=1

qm importdisk 9002 "$DEBIAN_IMG" "$STORAGE"
qm set 9002 \
  --scsihw virtio-scsi-pci \
  --scsi0 "${STORAGE}:vm-9002-disk-0" \
  --ide2 "${STORAGE}:cloudinit" \
  --boot c \
  --bootdisk scsi0 \
  --ipconfig0 ip=dhcp

qm template 9002
log "Debian 12 template created: ID 9002"

log ""
log "============================================================"
log "Templates ready. Next steps:"
log "  1. Import SOF-ELK OVA manually via Proxmox web UI"
log "     https://github.com/philhagen/sof-elk/releases"
log "     Convert to template after import → name: sof-elk-template"
log "  2. Upload Windows 10 ISO to ${ISO_STORAGE}:iso/"
log "  3. Upload Tsurugi Linux ISO to ${ISO_STORAGE}:iso/"
log "  4. Upload VirtIO drivers ISO to ${ISO_STORAGE}:iso/"
log "     https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/"
log "  5. Run: terraform init && terraform plan && terraform apply"
log "============================================================"
