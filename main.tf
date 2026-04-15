# =============================================================================
# ECrime Homelab — Proxmox Terraform Configuration
# Provisions all VMs across the 6 VLAN security zones
#
# Provider: Telmate/proxmox (community Proxmox Terraform provider)
# Docs:     https://registry.terraform.io/providers/Telmate/proxmox
#
# Usage:
#   terraform init
#   terraform plan -var-file="terraform.tfvars"
#   terraform apply -var-file="terraform.tfvars"
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9"
    }
  }

  # Store state locally — for production use a remote backend (Gitea, S3)
  backend "local" {
    path = "terraform.tfstate"
  }
}

# =============================================================================
# PROVIDER
# =============================================================================

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
  pm_log_enable       = false
  pm_timeout          = 600
}

# =============================================================================
# VLAN 10 — MANAGEMENT VMs
# =============================================================================

module "vm_gitea" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-gitea"
  vm_id       = 110
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 2
  memory      = 4096
  disk_size   = "60G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.10.10/24"
  gateway     = "10.0.10.1"
  vlan_tag    = 10
  tags        = ["management", "gitea", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

module "vm_vault" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-vault"
  vm_id       = 111
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 2
  memory      = 4096
  disk_size   = "40G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.10.11/24"
  gateway     = "10.0.10.1"
  vlan_tag    = 10
  tags        = ["management", "vault", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

# =============================================================================
# VLAN 20 — ANALYSIS VMs
# =============================================================================

module "vm_sift_remnux" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-sift-remnux"
  vm_id       = 200
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 16384
  disk_size   = "200G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.20.10/24"
  gateway     = "10.0.20.1"
  vlan_tag    = 20
  tags        = ["analysis", "dfir", "sift", "remnux", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

module "vm_tsurugi" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-tsurugi"
  vm_id       = 201
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 8192
  disk_size   = "120G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.20.11/24"
  gateway     = "10.0.20.1"
  vlan_tag    = 20
  tags        = ["analysis", "dfir", "tsurugi", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

module "vm_flarevm" {
  source        = "./modules/vm-windows"
  vm_name       = "ecrime-flare-vm"
  vm_id         = 202
  target_node   = var.proxmox_node
  clone         = var.windows10_template
  cores         = 4
  memory        = 16384
  disk_size     = "200G"
  disk_storage  = var.storage_pool_ssd
  ip_address    = "10.0.20.12/24"
  gateway       = "10.0.20.1"
  vlan_tag      = 20
  tags          = ["analysis", "dfir", "flarevm", "windows", "ecrime-homelab"]
}

module "vm_velociraptor" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-velociraptor"
  vm_id       = 203
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 8192
  disk_size   = "500G"    # Large — stores all endpoint artifacts
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.20.30/24"
  gateway     = "10.0.20.1"
  vlan_tag    = 20
  tags        = ["analysis", "hunting", "velociraptor", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

module "vm_zeek_suricata" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-sensor"
  vm_id       = 204
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 8192
  disk_size   = "200G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.20.31/24"
  gateway     = "10.0.20.1"
  vlan_tag    = 20
  tags        = ["analysis", "nsm", "zeek", "suricata", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

module "vm_ms_cloud" {
  source        = "./modules/vm-windows"
  vm_name       = "ecrime-ms-cloud"
  vm_id         = 205
  target_node   = var.proxmox_node
  clone         = var.windows10_template
  cores         = 4
  memory        = 8192
  disk_size     = "120G"
  disk_storage  = var.storage_pool_ssd
  ip_address    = "10.0.20.40/24"
  gateway       = "10.0.20.1"
  vlan_tag      = 20
  tags          = ["analysis", "cloud", "microsoft", "windows", "ecrime-homelab"]
}

module "vm_android_forensics" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-android"
  vm_id       = 206
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 8192
  disk_size   = "120G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.20.50/24"
  gateway     = "10.0.20.1"
  vlan_tag    = 20
  tags        = ["analysis", "mobile", "android", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

module "vm_crypto_tracing" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-crypto"
  vm_id       = 207
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 16384
  disk_size   = "500G"    # BlockSci needs large storage for blockchain data
  disk_storage = var.storage_pool_hdd
  ip_address  = "10.0.20.60/24"
  gateway     = "10.0.20.1"
  vlan_tag    = 20
  tags        = ["analysis", "crypto", "tracing", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

# =============================================================================
# VLAN 30 — DETONATION VMs (air-gapped)
# =============================================================================

module "vm_cape" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-cape"
  vm_id       = 300
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 8
  memory      = 32768     # CAPE needs plenty of RAM for nested VMs
  disk_size   = "500G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.30.10/24"
  gateway     = "10.0.30.1"
  vlan_tag    = 30
  tags        = ["detonation", "cape", "malware", "ecrime-homelab"]
  dns_servers = ["10.0.30.11"]   # INetSim provides fake DNS
  ssh_keys    = var.ssh_public_key
  # Enable nested virtualization for KVM-based analysis VMs
  nested_virtualization = true
}

module "vm_inetsim" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-inetsim"
  vm_id       = 301
  target_node = var.proxmox_node
  clone       = var.debian_template
  cores       = 2
  memory      = 4096
  disk_size   = "40G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.30.11/24"
  gateway     = "10.0.30.1"
  vlan_tag    = 30
  tags        = ["detonation", "inetsim", "malware", "ecrime-homelab"]
  dns_servers = ["127.0.0.1"]
  ssh_keys    = var.ssh_public_key
}

# =============================================================================
# VLAN 40 — INTELLIGENCE VMs
# =============================================================================

module "vm_misp" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-misp"
  vm_id       = 400
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 16384
  disk_size   = "200G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.40.10/24"
  gateway     = "10.0.40.1"
  vlan_tag    = 40
  tags        = ["intel", "misp", "threatintel", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

module "vm_opencti" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-opencti"
  vm_id       = 401
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 16384
  disk_size   = "200G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.40.11/24"
  gateway     = "10.0.40.1"
  vlan_tag    = 40
  tags        = ["intel", "opencti", "threatintel", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

module "vm_thehive" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-thehive"
  vm_id       = 402
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 16384
  disk_size   = "200G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.40.20/24"
  gateway     = "10.0.40.1"
  vlan_tag    = 40
  tags        = ["intel", "thehive", "cortex", "casemanagement", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

module "vm_shuffle" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-shuffle"
  vm_id       = 403
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 8192
  disk_size   = "80G"
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.40.22/24"
  gateway     = "10.0.40.1"
  vlan_tag    = 40
  tags        = ["intel", "shuffle", "soar", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

# =============================================================================
# VLAN 50 — LOGGING
# =============================================================================

module "vm_sofelk" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-sofelk"
  vm_id       = 500
  target_node = var.proxmox_node
  # SOF-ELK is best imported as OVA — this provisions a base Ubuntu if building from scratch
  clone       = var.ubuntu_template
  cores       = 8
  memory      = 32768     # Elasticsearch is RAM-hungry
  disk_size   = "1000G"   # Log retention storage
  disk_storage = var.storage_pool_hdd
  ip_address  = "10.0.50.10/24"
  gateway     = "10.0.50.1"
  vlan_tag    = 50
  tags        = ["logging", "sofelk", "siem", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
}

# =============================================================================
# VLAN 60 — EVIDENCE NAS
# =============================================================================

module "vm_nas" {
  source      = "./modules/vm-linux"
  vm_name     = "ecrime-nas"
  vm_id       = 600
  target_node = var.proxmox_node
  clone       = var.ubuntu_template
  cores       = 4
  memory      = 8192
  disk_size   = "60G"     # OS disk only — ZFS uses raw passthrough disks
  disk_storage = var.storage_pool_ssd
  ip_address  = "10.0.60.10/24"
  gateway     = "10.0.60.1"
  vlan_tag    = 60
  tags        = ["storage", "nas", "zfs", "evidence", "ecrime-homelab"]
  dns_servers = var.dns_servers
  ssh_keys    = var.ssh_public_key
  # ZFS raw disk passthrough — configure disk_passthroughs in host_vars
}
