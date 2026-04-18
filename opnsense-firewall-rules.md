# OPNsense Firewall Configuration — ECrime Homelab

## Overview

OPNsense runs as a VM on Proxmox and enforces all inter-VLAN routing policies.
The most critical rule is the **complete isolation of VLAN 30 (Detonation)**.

---

## VLAN Interface Summary

| Interface | VLAN | Subnet | Egress Policy |
|---|---|---|---|
| LAN / vmbr10 | 10 | 10.0.10.0/24 | NO egress — management only |
| ANALYSIS / vmbr20 | 20 | 10.0.20.0/24 | Logged egress — allowlist |
| DETONATION / vmbr30 | 30 | 10.0.30.0/24 | ZERO egress — air-gapped |
| INTEL / vmbr40 | 40 | 10.0.40.0/24 | Egress to threat feed allowlist only |
| LOGGING / vmbr50 | 50 | 10.0.50.0/24 | Receive-only — no egress |
| EVIDENCE / vmbr60 | 60 | 10.0.60.0/24 | NO egress — NFS only |
| WAN | — | DHCP/Static | Internet uplink |

---

## Firewall Rules (by Interface)

### VLAN 10 — Management (NO egress)

```
Action  Proto  Source           Destination      Port    Description
BLOCK   *      10.0.10.0/24     WAN              *       Block all internet egress
PASS    TCP    10.0.10.0/24     10.0.20.0/24     22      SSH to analysis VMs
PASS    TCP    10.0.10.0/24     10.0.30.0/24     22      SSH to detonation (admin)
PASS    TCP    10.0.10.0/24     10.0.40.0/24     22      SSH to intel VMs
PASS    TCP    10.0.10.0/24     10.0.50.0/24     22      SSH to logging VMs
PASS    TCP    10.0.10.0/24     10.0.60.0/24     22      SSH to NAS
PASS    UDP    10.0.10.0/24     *                123     NTP egress (chrony)
BLOCK   *      10.0.10.0/24     *                *       Default deny
```

### VLAN 20 — Analysis (Monitored egress)

```
Action  Proto  Source           Destination      Port    Description
PASS    *      10.0.20.0/24     10.0.50.10       5514    Syslog to SOF-ELK
PASS    *      10.0.20.0/24     10.0.50.10       5044    Beats to SOF-ELK
PASS    *      10.0.20.0/24     10.0.50.10       9200    ES API to SOF-ELK
PASS    *      10.0.20.0/24     10.0.60.10       2049    NFS to Evidence NAS
PASS    *      10.0.20.0/24     10.0.40.0/24     *       Access intel stack
PASS    TCP    10.0.20.0/24     WAN              80,443  HTTP/HTTPS (logged, filtered)
BLOCK   *      10.0.20.0/24     10.0.30.0/24     *       BLOCK detonation VLAN
BLOCK   *      10.0.20.0/24     *                *       Default deny
```

### VLAN 30 — Detonation (COMPLETE ISOLATION)

```
Action  Proto  Source           Destination      Port    Description
PASS    *      10.0.30.10       10.0.50.10       5514    CAPE logs to SOF-ELK (one-way)
BLOCK   *      10.0.30.0/24     10.0.10.0/24     *       Block management VLAN
BLOCK   *      10.0.30.0/24     10.0.20.0/24     *       Block analysis VLAN
BLOCK   *      10.0.30.0/24     10.0.40.0/24     *       Block intel VLAN
BLOCK   *      10.0.30.0/24     10.0.60.0/24     *       Block evidence NAS
BLOCK   *      10.0.30.0/24     WAN              *       Block ALL internet
BLOCK   *      10.0.30.0/24     *                *       Default deny ALL
```

> ⚠️ **CRITICAL:** The VLAN 30 BLOCK rules must be the first rules evaluated.
> Verify with: `pfctl -sr | grep "10.0.30"` after applying.

### VLAN 40 — Intel (Threat feed allowlist)

```
Action  Proto  Source           Destination      Port    Description
PASS    *      10.0.40.0/24     10.0.50.10       5514    Syslog to SOF-ELK
PASS    TCP    10.0.40.0/24     WAN              443     MISP feeds (HTTPS only)
PASS    TCP    10.0.40.0/24     WAN              443     OpenCTI connector feeds
BLOCK   *      10.0.40.0/24     10.0.30.0/24     *       Block detonation VLAN
BLOCK   *      10.0.40.0/24     10.0.60.0/24     *       Block evidence NAS
BLOCK   *      10.0.40.0/24     *                *       Default deny
```

### VLAN 50 — Logging (Receive-only)

```
Action  Proto  Source           Destination      Port    Description
PASS    *      10.0.0.0/8       10.0.50.10       5514    Accept syslog from all VLANs
PASS    *      10.0.0.0/8       10.0.50.10       5044    Accept Beats from all VLANs
PASS    *      10.0.20.0/24     10.0.50.10       5601    Kibana access from analysis
PASS    *      10.0.10.0/24     10.0.50.10       5601    Kibana access from management
BLOCK   *      10.0.50.0/24     WAN              *       Block all egress
BLOCK   *      10.0.50.0/24     *                *       Default deny
```

### VLAN 60 — Evidence NAS (NFS only)

```
Action  Proto  Source           Destination      Port    Description
PASS    TCP/UDP 10.0.20.0/24    10.0.60.10       2049    NFS from analysis VMs
PASS    TCP/UDP 10.0.20.0/24    10.0.60.10       111     RPC portmapper
PASS    *      10.0.60.10       10.0.50.10       5514    Syslog to SOF-ELK
BLOCK   *      10.0.60.0/24     WAN              *       Block all egress
BLOCK   *      10.0.60.0/24     *                *       Default deny
```

---

## IDS/IPS — Suricata Plugin

Enable Suricata inline on the WAN interface:

1. OPNsense → Services → Intrusion Detection → Administration
2. Enable: ✅ | IPS Mode: ✅ | Promiscuous Mode: ✅
3. Interfaces: WAN, ANALYSIS (vmbr20)
4. Download rulesets: ET Open, ET Pro (free), OISF Suricata rules
5. Log to SOF-ELK via syslog → `10.0.50.10:5514`

---

## Importing This Config

```bash
# Export current OPNsense config (from OPNsense web UI):
# System → Configuration → Backups → Download

# Import this template:
# System → Configuration → Backups → Restore
# Select: infrastructure/network/opnsense-config.xml

# IMPORTANT: Review all rules after import — IPs may differ from your setup
```
