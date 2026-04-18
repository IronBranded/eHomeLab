# Network Design — VLAN Topology & Firewall Rules

---

## VLAN Summary Table

| VLAN | ID | Subnet | Purpose | Internet | Inter-VLAN |
|---|---|---|---|---|---|
| Management | 10 | `10.0.10.0/24` | Proxmox, Gitea, Vault, WireGuard | ❌ None | Admin only |
| Analysis | 20 | `10.0.20.0/24` | DFIR workstations, Velociraptor, NSM | ✅ Monitored | → VLAN 50, 60 (read) |
| Detonation | 30 | `10.0.30.0/24` | CAPE, INetSim, Win detonation | ❌ Air-gapped | ❌ None |
| Cloud/Intel | 40 | `10.0.40.0/24` | TheHive, MISP, OpenCTI, Shuffle | ✅ Allowlist | → VLAN 50 |
| Logging | 50 | `10.0.50.0/24` | SOF-ELK | ❌ None | Receive-only |
| Evidence NAS | 60 | `10.0.60.0/24` | ZFS NAS | ❌ None | → VLAN 20 (ro NFS) |

---

## OPNsense Firewall Rules

### VLAN 10 — Management (default deny all egress)

| Direction | Source | Destination | Port | Action |
|---|---|---|---|---|
| In | VLAN10 net | VLAN20 net | SSH/22 | Allow |
| In | VLAN10 net | VLAN30 net | SSH/22 | Allow (ProxyJump) |
| In | VLAN10 net | VLAN40 net | SSH/22 | Allow |
| In | VLAN10 net | VLAN50 net | SSH/22 | Allow |
| In | VLAN10 net | VLAN60 net | SSH/22 | Allow |
| In | VLAN10 net | Any | Any | **Block** |

### VLAN 20 — Analysis (monitored egress)

| Direction | Source | Destination | Port | Action |
|---|---|---|---|---|
| In | VLAN20 net | VLAN50 net | 5514,5044,9200 | Allow (logging) |
| In | VLAN20 net | VLAN60 net | 2049,111 | Allow (NFS read-only) |
| In | VLAN20 net | VLAN40 net | 9000,9001,9200,8080 | Allow (intel tools) |
| In | VLAN20 net | Internet | 80,443 | Allow via IDS |
| In | VLAN20 net | VLAN30 net | Any | **Block** |

### VLAN 30 — Detonation (HARD air-gap)

| Direction | Source | Destination | Port | Action |
|---|---|---|---|---|
| In | VLAN30 net | Any | Any | **Block ALL** |
| In | Any | VLAN30 net | Any | **Block ALL** |
| Out | VLAN30 net | VLAN50 net | 5514 | Allow (log push — one-way) |

> **Note:** CAPE → SOF-ELK log forwarding uses a one-way isolated bridge. VLAN 30 has zero IP routing to any other VLAN. The log push is achieved via a dedicated bridge port on the Proxmox host.

### VLAN 40 — Cloud/Intel (allowlisted egress)

| Direction | Source | Destination | Port | Action |
|---|---|---|---|---|
| In | VLAN40 net | VLAN50 net | 5514,5044 | Allow (logging) |
| In | VLAN40 net | Intel feed IPs | 80,443 | Allow (allowlist) |
| In | VLAN40 net | Any | Any | **Block** |

### VLAN 50 — Logging (receive-only)

| Direction | Source | Destination | Port | Action |
|---|---|---|---|---|
| In | Any | VLAN50:5514 | TCP/UDP | Allow (syslog) |
| In | Any | VLAN50:5044 | TCP | Allow (beats) |
| In | VLAN50 net | Any | Any | **Block** |

### VLAN 60 — Evidence NAS (NFS only)

| Direction | Source | Destination | Port | Action |
|---|---|---|---|---|
| In | VLAN20 net | VLAN60:2049 | TCP/UDP | Allow (NFS) |
| In | VLAN20:10.0.20.10 | VLAN60:2049 | TCP | Allow (write — acquisition host only) |
| In | Any other | VLAN60 | Any | **Block** |

---

## WireGuard Remote Access

Remote analysts connect via WireGuard to `10.0.10.20:51820`.  
Upon connection they receive an IP in `10.0.10.128/25` and can reach:

- VLAN 10 management services (Proxmox UI, Gitea, Vault)
- VLAN 20 analysis hosts via SSH / VNC
- VLAN 40 intel platforms (TheHive, MISP, OpenCTI)
- VLAN 50 SOF-ELK Kibana dashboard

WireGuard clients cannot reach VLAN 30 (detonation) or VLAN 60 (NAS) — enforced by OPNsense.

---

## Proxmox Bridge Layout

| Bridge | VLAN | Connected VMs |
|---|---|---|
| `vmbr10` | 10 | Gitea, Vault, WireGuard |
| `vmbr20` | 20 | SIFT+REMnux, Tsurugi, Flare-VM, Velociraptor, Zeek/Suricata, MS Cloud, Android, Crypto |
| `vmbr30` | 30 | CAPE, INetSim, Win detonation |
| `vmbr40` | 40 | TheHive, Cortex, MISP, OpenCTI, Shuffle |
| `vmbr50` | 50 | SOF-ELK |
| `vmbr60` | 60 | ZFS Evidence NAS |
