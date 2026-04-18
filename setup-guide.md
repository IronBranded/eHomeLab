# ECrime Homelab — Full Setup Guide

> **Time estimate:** 7 weeks for full stack | Phase 1 alone takes 2–3 days  
> **Prerequisites:** Proxmox VE installed on bare metal, SSH access to host

---

## Phase 1 — Foundation

### 1.1 Proxmox VE Installation

Install Proxmox VE 8.x from the official ISO onto your bare metal host.  
After install, configure the management IP and update packages:

```bash
apt update && apt full-upgrade -y
pveam update
```

### 1.2 Create Proxmox API Token for Terraform

Run the setup script from your workstation:

```bash
ssh root@<proxmox-ip> 'bash -s' < infrastructure/proxmox/scripts/proxmox-api-setup.sh
```

Copy the output `Token ID` and `Token Secret` into `terraform.tfvars`.

### 1.3 Configure OPNsense Firewall VM

1. Download the OPNsense AMD64 DVD ISO from `https://opnsense.org/download/`
2. Upload to Proxmox: **Datacenter → local → ISO Images → Upload**
3. Create a new VM (ID 100) with 2 vCPUs, 4GB RAM, 16GB disk
4. Attach the ISO and install OPNsense
5. Assign two NICs: `vmbr0` (WAN) and `vmbr1` (LAN/trunk)
6. Configure VLANs 10/20/30/40/50/60 as VLAN interfaces on the LAN trunk

**Critical firewall rules to create in OPNsense:**

| Source VLAN | Destination | Action | Notes |
|---|---|---|---|
| VLAN 30 | Any | Block | Detonation — fully air-gapped |
| VLAN 60 | Any except VLAN 20 | Block | NAS — only analysis can mount |
| VLAN 50 | Any (outbound) | Block | SOF-ELK — receive-only |
| VLAN 20 | Internet | Allow (monitored) | Analysis — Zeek/Suricata inspect |
| VLAN 40 | Threat feed IPs | Allow (allowlist) | Intel feeds only |
| VLAN 10 | Any | Block | Management — no egress |

### 1.4 Build Cloud-Init VM Templates

Run the template builder on your Proxmox host:

```bash
ssh root@<proxmox-ip> 'bash -s' < infrastructure/proxmox/scripts/build-templates.sh
```

After the script completes, manually:
1. Import the SOF-ELK OVA via **Proxmox UI → local → Content → Upload**  
   Download from: `https://github.com/philhagen/sof-elk/releases`
2. Upload `Win10_22H2_English_x64.iso` to `local:iso/`
3. Upload `tsurugi-lab-2024.1-amd64.iso` to `local:iso/`
4. Upload `virtio-win.iso` to `local:iso/`  
   Download from: `https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/`

### 1.5 Configure Linux Bridges for VLANs

On the Proxmox host, edit `/etc/network/interfaces`:

```
# Management VLAN 10
auto vmbr10
iface vmbr10 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0

# Analysis VLAN 20
auto vmbr20
iface vmbr20 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0

# Detonation VLAN 30
auto vmbr30
iface vmbr30 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0

# Intel VLAN 40
auto vmbr40
iface vmbr40 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0

# Logging VLAN 50
auto vmbr50
iface vmbr50 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0

# Evidence NAS VLAN 60
auto vmbr60
iface vmbr60 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
```

Apply: `systemctl restart networking`

### 1.6 Provision All VMs with Terraform

```bash
cd infrastructure/proxmox/terraform
cp terraform.tfvars.tmpl terraform.tfvars
nano terraform.tfvars        # Fill in your values
terraform init
terraform plan               # Review — 18 VMs will be created
terraform apply
```

### 1.7 Generate SSH Key for Ansible

```bash
ssh-keygen -t ed25519 -C "ecrime-homelab" -f ~/.ssh/ecrime_homelab_ed25519
# Copy the public key path into terraform.tfvars → ssh_public_key
```

---

## Phase 2 — DFIR Core

### 2.1 Configure Ansible Inventory and Vault

```bash
cd ansible/
cp inventory.ini.tmpl inventory.ini
nano inventory.ini                       # Confirm all IPs match Terraform outputs

cp group_vars/vault.yml.tmpl group_vars/vault.yml
nano group_vars/vault.yml                # Set all CHANGEME values

# Generate a strong vault password
openssl rand -base64 32 > ~/.vault_pass
chmod 600 ~/.vault_pass

ansible-vault encrypt group_vars/vault.yml --vault-password-file ~/.vault_pass
```

### 2.2 Bootstrapping WinRM on Windows VMs

Before Ansible can manage Windows VMs, WinRM must be enabled manually on each:

1. Open a console to the Windows VM in Proxmox UI
2. Run in PowerShell as Administrator:

```powershell
# Enable WinRM
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
Enable-PSRemoting -Force
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
New-NetFirewallRule -Name "WinRM HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5986
```

### 2.3 Run Ansible — Full Deploy

```bash
# Full deploy (all 7 phases)
ansible-playbook -i inventory.ini site.yml --vault-password-file ~/.vault_pass

# Single phase
ansible-playbook -i inventory.ini site.yml --tags phase2 --vault-password-file ~/.vault_pass

# Single role
ansible-playbook -i inventory.ini site.yml --tags velociraptor --vault-password-file ~/.vault_pass
```

### 2.4 Install SIFT + REMnux (automated via role)

The `sift_remnux` role handles this automatically. It runs:
- `sift install --mode=server` (~30 min)
- `remnux install --mode=addon` (~30 min)

Both run async with 60-minute timeout. Monitor progress:

```bash
ssh analyst@10.0.20.10 'tail -f /var/log/syslog | grep -E "sift|remnux"'
```

---

## Phase 3 — Threat Hunting Stack

### 3.1 Velociraptor Client Deployment

After the Velociraptor server role runs, the client MSI is built at:
`/opt/velociraptor/clients/velociraptor-client.msi`

Deploy to Windows endpoints via Ansible or GPO:

```bash
# Copy MSI to Flare-VM
scp /opt/velociraptor/clients/velociraptor-client.msi analyst@10.0.20.12:C:/temp/
```

### 3.2 Configure Zeek Span Port

On the Proxmox host, configure port mirroring so `eth1` on the sensor VM sees all VLAN 20 traffic:

```bash
# On Proxmox host — mirror vmbr20 to sensor VM's second interface
ovs-vsctl add-port vmbr20 tap<vmid>i1 \
  -- set Port tap<vmid>i1 mirror=@m \
  -- --id=@m create Mirror name=vlan20-mirror \
     select-all=true \
     output-port=tap<vmid>i1
```

### 3.3 Import SOF-ELK Dashboards

After the `sof_elk` role runs, verify Kibana is accessible:
`http://10.0.50.10:5601`

Default SOF-ELK credentials: `elastic` / (check role output)

---

## Phase 4 — Malware Lab

### 4.1 CAPE Windows Detonation VM

After Terraform creates `win-detonation` (10.0.30.12):

1. Install Windows 10 from ISO via Proxmox console
2. Install VirtIO drivers from the attached ISO
3. Set a static IP: `10.0.30.12/24`, gateway `10.0.30.1`, DNS `10.0.30.11`
4. Install CAPE agent: copy from CAPE server and run
5. **Take a snapshot named `clean-baseline`** — CAPE will revert to this

```bash
# On CAPE server — generate agent
cd /opt/cape/CAPEv2
python utils/agent.py
# Copy agent.pyw to Windows VM and run as Administrator
```

### 4.2 Verify INetSim Is Reachable from Detonation VMs

From within a detonation VM:
```
nslookup evil.com 10.0.30.11   # Should return 10.0.30.11
curl http://10.0.30.11/         # Should return INetSim HTTP response
```

---

## Phase 5 — Intelligence Stack

### 5.1 TheHive + Cortex Initial Setup

Access TheHive at `http://10.0.40.20:9000`

Default admin credentials: `admin@thehive.local` / `secret`  
**Change immediately on first login.**

Connect Cortex:
1. In Cortex UI, create an organisation and generate an API key
2. Paste the API key into `thehive.conf.j2` → redeploy, or update via TheHive UI

### 5.2 MISP Initial Setup

Access MISP at `https://10.0.40.10`

Default credentials: `admin@admin.test` / `admin`  
**Change immediately on first login.**

Enable threat feeds:
```bash
# Via Ansible (feeds enabled in role)
ansible-playbook -i inventory.ini site.yml --tags misp --vault-password-file ~/.vault_pass

# Or manually via MISP UI: Sync → Feeds → Enable selected feeds
```

---

## Phase 7 — Verification

Run the full verification suite:

```bash
ansible-playbook -i inventory.ini site.yml --tags verify --vault-password-file ~/.vault_pass
```

Check individual service URLs after deploy:

| Service | URL | Default Credentials |
|---|---|---|
| Proxmox UI | `https://10.0.10.1:8006` | root / (set during install) |
| Velociraptor | `https://10.0.20.30:8889` | admin / (vault) |
| Kibana (SOF-ELK) | `http://10.0.50.10:5601` | elastic / (vault) |
| TheHive | `http://10.0.40.20:9000` | admin@thehive.local / secret |
| Cortex | `http://10.0.40.20:9001` | admin / (set on first login) |
| MISP | `https://10.0.40.10` | admin@admin.test / admin |
| OpenCTI | `http://10.0.40.11:8080` | admin@ecrime.lab / (vault) |
| Shuffle | `https://10.0.40.22:3443` | admin / (vault) |
| CAPE | `http://10.0.30.10:8000` | (no default — set in UI) |
| Gitea | `http://10.0.10.10:3000` | (set on first login) |
| Vault | `http://10.0.10.11:8200` | (root token in vault.yml) |
| SpiderFoot | `http://10.0.20.60:5001` | (no auth by default) |

---

## Troubleshooting

**Ansible cannot reach a VM:**
```bash
ansible <hostname> -i inventory.ini -m ping --vault-password-file ~/.vault_pass
ssh-keyscan <ip> >> ~/.ssh/known_hosts
```

**Terraform plan shows no changes but VMs not created:**
```bash
terraform state list    # Check what Terraform thinks exists
terraform refresh       # Re-sync state with Proxmox
```

**CAPE detonation VM not registering:**
- Verify detonation VM has static IP in `192.168.100.0/24` range
- Verify CAPE resultserver is listening: `ss -tlnp | grep 2042` on CAPE host
- Verify INetSim is running: `systemctl status inetsim`

**SOF-ELK not receiving logs:**
```bash
# Test syslog forwarding from any host
logger -n 10.0.50.10 -P 5514 --tcp "Test message from $(hostname)"
# Check in Kibana: Discover → search for "Test message"
```
