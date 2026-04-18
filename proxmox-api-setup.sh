#!/usr/bin/env bash
# =============================================================================
# proxmox-api-setup.sh — Create least-privilege Terraform API token
# Run on the Proxmox host as root BEFORE running terraform
# =============================================================================
# Usage: ssh root@10.0.10.1 'bash -s' < scripts/proxmox-api-setup.sh
# =============================================================================

set -euo pipefail

log() { echo "[$(date +%H:%M:%S)] $*"; }

log "Creating terraform role with least-privilege permissions..."

pveum role add TerraformRole \
  --privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU \
           VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType \
           VM.Config.Memory VM.Config.Network VM.Config.Options \
           VM.Monitor VM.Audit VM.PowerMgmt VM.Snapshot \
           Datastore.AllocateSpace Datastore.Audit \
           SDN.Use Pool.Audit Sys.Audit" \
  2>/dev/null || log "Role already exists — skipping"

log "Creating terraform system user..."
pveum user add terraform@pam \
  --comment "Terraform provisioning account — ecrime homelab" \
  2>/dev/null || log "User already exists — skipping"

log "Assigning role to terraform user (datacenter scope)..."
pveum aclmod / \
  --users terraform@pam \
  --roles TerraformRole

log "Creating API token..."
TOKEN_OUTPUT=$(pveum user token add terraform@pam ecrime \
  --privsep 0 \
  --comment "ECrime homelab Terraform token" \
  --output-format json)

TOKEN_SECRET=$(echo "$TOKEN_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['value'])")

log ""
log "============================================================"
log " API Token created successfully"
log " Token ID:     terraform@pam!ecrime"
log " Token Secret: ${TOKEN_SECRET}"
log ""
log " Add these to terraform.tfvars:"
log "   proxmox_api_token_id     = \"terraform@pam!ecrime\""
log "   proxmox_api_token_secret = \"${TOKEN_SECRET}\""
log "============================================================"
