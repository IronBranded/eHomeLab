# =============================================================================
# ECrime Homelab — Terraform Variables
# =============================================================================

# ── Proxmox connection ────────────────────────────────────────────────────────
variable "proxmox_api_url" {
  description = "Proxmox API URL — e.g. https://10.0.10.1:8006/api2/json"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID — format: terraform@pam!ecrime"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret UUID"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name (hostname shown in Proxmox UI)"
  type        = string
  default     = "pve"
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification — true for self-signed Proxmox certs"
  type        = bool
  default     = true
}

# ── Templates (cloud-init clones) ─────────────────────────────────────────────
variable "ubuntu_template" {
  description = "Proxmox template name for Ubuntu 22.04 cloud-init"
  type        = string
  default     = "ubuntu-2204-cloudinit-template"
}

variable "ubuntu2004_template" {
  description = "Proxmox template name for Ubuntu 20.04 (CAPE requirement)"
  type        = string
  default     = "ubuntu-2004-cloudinit-template"
}

variable "debian_template" {
  description = "Proxmox template name for Debian 12 cloud-init"
  type        = string
  default     = "debian-12-cloudinit-template"
}

variable "sofelk_template" {
  description = "Proxmox template name for SOF-ELK (imported from OVA)"
  type        = string
  default     = "sof-elk-template"
}

# ── Storage pools ─────────────────────────────────────────────────────────────
variable "vm_storage_pool" {
  description = "Proxmox storage pool for VM OS disks (NVMe/SSD)"
  type        = string
  default     = "local-lvm"
}

variable "nas_storage_pool" {
  description = "Proxmox storage pool for NAS data disks (HDD / large)"
  type        = string
  default     = "local-hdd"
}

variable "iso_storage" {
  description = "Proxmox storage pool where ISO images are uploaded"
  type        = string
  default     = "local"
}

# ── SSH ───────────────────────────────────────────────────────────────────────
variable "ssh_public_key" {
  description = "SSH public key injected into all cloud-init VMs"
  type        = string
  sensitive   = true
}

# ── Networking ────────────────────────────────────────────────────────────────
variable "dns_server" {
  description = "Internal DNS resolver IP (OPNsense gateway)"
  type        = string
  default     = "10.0.10.1"
}

# ── Per-VLAN gateway IPs ──────────────────────────────────────────────────────
variable "gw_vlan10" {
  description = "Gateway for VLAN 10 (management)"
  type        = string
  default     = "10.0.10.1"
}

variable "gw_vlan20" {
  description = "Gateway for VLAN 20 (analysis)"
  type        = string
  default     = "10.0.20.1"
}

variable "gw_vlan30" {
  description = "Gateway for VLAN 30 (detonation — internal only)"
  type        = string
  default     = "10.0.30.1"
}

variable "gw_vlan40" {
  description = "Gateway for VLAN 40 (intel)"
  type        = string
  default     = "10.0.40.1"
}

variable "gw_vlan50" {
  description = "Gateway for VLAN 50 (logging)"
  type        = string
  default     = "10.0.50.1"
}

variable "gw_vlan60" {
  description = "Gateway for VLAN 60 (evidence NAS)"
  type        = string
  default     = "10.0.60.1"
}
