# =============================================================================
# ECrime Homelab — Terraform Outputs
# Run: terraform output          (after apply)
#      terraform output -json    (machine-readable for Ansible inventory)
# =============================================================================

# ── VLAN 10 — Management ──────────────────────────────────────────────────────
output "gitea_ip" {
  description = "Gitea self-hosted Git server IP"
  value       = "10.0.10.10"
}

output "vault_ip" {
  description = "HashiCorp Vault secrets manager IP"
  value       = "10.0.10.11"
}

# ── VLAN 20 — Analysis ────────────────────────────────────────────────────────
output "sift_remnux_ip" {
  description = "SIFT + REMnux DFIR workstation IP"
  value       = "10.0.20.10"
}

output "tsurugi_ip" {
  description = "Tsurugi Linux live forensics IP"
  value       = "10.0.20.11"
}

output "flare_vm_ip" {
  description = "Flare-VM Windows RE workstation IP"
  value       = "10.0.20.12"
}

output "velociraptor_ip" {
  description = "Velociraptor EDR server IP"
  value       = "10.0.20.30"
}

output "velociraptor_gui_url" {
  description = "Velociraptor web GUI URL"
  value       = "https://10.0.20.30:8889"
}

output "zeek_suricata_ip" {
  description = "Zeek + Suricata NSM sensor IP"
  value       = "10.0.20.31"
}

output "ms_cloud_ip" {
  description = "Microsoft cloud forensics VM IP"
  value       = "10.0.20.40"
}

output "android_forensics_ip" {
  description = "Android forensics VM IP"
  value       = "10.0.20.50"
}

output "crypto_tracing_ip" {
  description = "Crypto tracing VM IP"
  value       = "10.0.20.60"
}

# ── VLAN 30 — Detonation (air-gapped) ────────────────────────────────────────
output "cape_ip" {
  description = "CAPE Sandbox IP (VLAN 30 — air-gapped)"
  value       = "10.0.30.10"
}

output "cape_web_url" {
  description = "CAPE Sandbox web UI URL (accessible from VLAN 20 only)"
  value       = "http://10.0.30.10:8000"
}

output "inetsim_ip" {
  description = "INetSim fake internet IP (VLAN 30 — air-gapped)"
  value       = "10.0.30.11"
}

# ── VLAN 40 — Intelligence ────────────────────────────────────────────────────
output "misp_ip" {
  description = "MISP threat intelligence platform IP"
  value       = "10.0.40.10"
}

output "misp_url" {
  description = "MISP web UI URL"
  value       = "https://10.0.40.10"
}

output "opencti_ip" {
  description = "OpenCTI structured threat intel IP"
  value       = "10.0.40.11"
}

output "opencti_url" {
  description = "OpenCTI web UI URL"
  value       = "http://10.0.40.11:8080"
}

output "thehive_ip" {
  description = "TheHive 4 + Cortex case management IP"
  value       = "10.0.40.20"
}

output "thehive_url" {
  description = "TheHive 4 web UI URL"
  value       = "http://10.0.40.20:9000"
}

output "cortex_url" {
  description = "Cortex enrichment engine URL"
  value       = "http://10.0.40.20:9001"
}

output "shuffle_ip" {
  description = "Shuffle SOAR IP"
  value       = "10.0.40.22"
}

output "shuffle_url" {
  description = "Shuffle SOAR web UI URL"
  value       = "https://10.0.40.22:3443"
}

# ── VLAN 50 — Logging ────────────────────────────────────────────────────────
output "sofelk_ip" {
  description = "SOF-ELK SIEM IP"
  value       = "10.0.50.10"
}

output "kibana_url" {
  description = "SOF-ELK Kibana dashboard URL"
  value       = "http://10.0.50.10:5601"
}

output "elasticsearch_url" {
  description = "SOF-ELK Elasticsearch API URL"
  value       = "http://10.0.50.10:9200"
}

# ── VLAN 60 — Evidence NAS ────────────────────────────────────────────────────
output "nas_ip" {
  description = "ZFS evidence NAS IP"
  value       = "10.0.60.10"
}

output "nas_nfs_path" {
  description = "NFS mount path for analysis VMs (read-only)"
  value       = "10.0.60.10:/srv/evidence"
}

# ── Quick-reference summary ───────────────────────────────────────────────────
output "lab_summary" {
  description = "Full lab service URL reference"
  value = {
    velociraptor = "https://10.0.20.30:8889"
    thehive      = "http://10.0.40.20:9000"
    cortex       = "http://10.0.40.20:9001"
    misp         = "https://10.0.40.10"
    opencti      = "http://10.0.40.11:8080"
    shuffle      = "https://10.0.40.22:3443"
    kibana       = "http://10.0.50.10:5601"
    cape         = "http://10.0.30.10:8000"
    gitea        = "http://10.0.10.10:3000"
    vault        = "http://10.0.10.11:8200"
  }
}
