# 🔍 ECrime Homelab

> **A plug-and-play, forensically sound, open-source homelab infrastructure for digital forensics, incident response, malware analysis, threat hunting, crypto tracing, and mobile forensics.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Open Source](https://img.shields.io/badge/Tools-100%25%20Open%20Source-green.svg)]()
[![Platform](https://img.shields.io/badge/Hypervisor-Proxmox%20VE-orange.svg)]()
[![Forensics](https://img.shields.io/badge/Standard-ISO%2027037%20aligned-red.svg)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 📌 Overview

ECrime Homelab is a **fully open-source**, infrastructure-as-code homelab designed for:

- **Digital Forensics & Incident Response (DFIR)** — live, dead-box, cloud, and mobile
- **Malware Analysis & Reverse Engineering** — static, dynamic, and behavioral
- **Threat Hunting** — endpoint telemetry, network, and log-based
- **Crypto Tracing** — blockchain analytics and wallet attribution
- **OpSec Research** — OSINT, attribution, and counter-intelligence
- **Forensic Reporting** — court-admissible chain of custody workflows

Scope targets: **Windows OS**, **Android**, **Microsoft 365 / Azure / Entra ID cloud**

Built for: CTF competitors, certification candidates (GCFE, GCFA, GREM, GCTI, GCFR, BTL1/2), researchers, and practitioners.

> ⚠️ **Legal Notice:** This lab is strictly for authorized research, education, and lawful investigations. All detonation environments are air-gapped. Users are responsible for compliance with applicable laws. See [LEGAL.md](docs/LEGAL.md).

---

## 🏗️ Architecture Summary

```
┌──────────────────────────────────────────────────────────────────┐
│                     PROXMOX VE HYPERVISOR                        │
│              (Bare metal: 64–128GB RAM, 12+ cores, 8TB)          │
└──────────────────────────────┬───────────────────────────────────┘
                               │
         ┌─────────────────────┼──────────────────────┐
         │                     │                      │
   ┌─────▼──────┐       ┌──────▼──────┐       ┌──────▼──────┐
   │  VLAN 10   │       │  VLAN 20    │       │  VLAN 30    │
   │ Management │       │  Analysis   │       │ Detonation  │
   │ (no egress)│       │ (monitored) │       │ (air-gapped)│
   └─────┬──────┘       └──────┬──────┘       └──────┬──────┘
         │                     │                      │
   ┌─────▼──────┐       ┌──────▼──────┐       ┌──────▼──────┐
   │  VLAN 40   │       │  VLAN 50    │       │  VLAN 60    │
   │ Cloud/Intel│       │  Logging    │       │ Evidence    │
   │(egress ctrl)│      │  (SOF-ELK)  │       │  NAS (ZFS)  │
   └────────────┘       └─────────────┘       └─────────────┘
```

Full diagram: [ARCHITECTURE.md](docs/ARCHITECTURE.md) | [network-diagram.mermaid](infrastructure/network/network-diagram.mermaid)

---

## 🧰 Full Toolstack (100% Open Source)

### 🔬 DFIR Workstations

| VM | Purpose | License |
|---|---|---|
| **SIFT Workstation + REMnux** | Primary DFIR + memory/network malware analysis | Apache 2.0 / Custom |
| **Tsurugi Linux** | Live forensics, mobile triage, OSINT | GPL |
| **Flare-VM** (Windows) | Windows malware RE — x64dbg, Ghidra, dnSpy, PEStudio | Apache 2.0 |

### 🏹 Threat Hunting & Endpoint

| VM | Purpose | License |
|---|---|---|
| **Velociraptor** | EDR, live response, VQL hunt queries | Apache 2.0 |
| **Zeek + Suricata** | Network sensor, IDS/NSM | BSD / GPL |

### 🦠 Malware Analysis

| VM | Purpose | License |
|---|---|---|
| **CAPE Sandbox** | Dynamic behavioral malware detonation | GPL |
| **INetSim** | Simulated internet services for malware | GPL |

### ☁️ Cloud Forensics (Microsoft)

| Tool | Purpose | License |
|---|---|---|
| **Microsoft Extractor Suite** | M365 / Entra ID / Azure log extraction | MIT |
| **Microsoft Analyzer Suite** | Unified audit log parsing and analysis | MIT |
| **ROADtools** | Azure/Entra ID deep enumeration and forensics | MIT |
| **Hawk** | Microsoft cloud threat hunting | MIT |

### 📱 Mobile Forensics (Android)

| Tool | Purpose | License |
|---|---|---|
| **ALEAPP** | Android artifact parsing (logs, apps, protobuf) | MIT |
| **MVT (Mobile Verification Toolkit)** | Spyware / stalkerware detection | Apache 2.0 |
| **Andriller CE** | Android DB / APK forensics | Apache 2.0 |

### 📊 Log Analysis & SIEM

| VM | Purpose | License |
|---|---|---|
| **SOF-ELK** | DFIR-tuned Elastic stack — log aggregation, visualization | SANS / Elastic |
| **Eric Zimmerman Tools** | Windows artifact parsers (MFT, registry, prefetch, LNK, JLE) | MIT / Freeware |

### 🧠 Threat Intelligence & Case Management

| VM | Purpose | License |
|---|---|---|
| **MISP** | IOC sharing, threat intelligence platform | AGPL |
| **OpenCTI** | Structured threat intel, STIX/TAXII | Apache 2.0 |
| **TheHive 4** | Incident response case management | AGPL |
| **Cortex** | Observable enrichment and responder automation | AGPL |
| **Shuffle** | Open-source SOAR orchestration | AGPL |

### 🪙 Crypto Tracing

| Tool | Purpose | License |
|---|---|---|
| **GraphSense** | Blockchain analytics — BTC, ETH, LTC, ZEC | MIT |
| **BlockSci** | High-performance blockchain analysis framework | Apache 2.0 |
| **SpiderFoot** | OSINT automation with crypto/wallet transforms | MIT |

### 🛡️ Infrastructure

| Component | Purpose | License |
|---|---|---|
| **OPNsense** | Firewall, VLAN enforcement, IDS | BSD |
| **WireGuard** | Secure remote access VPN | GPL |
| **Gitea** | Self-hosted Git (lab documentation, playbooks) | MIT |
| **HashiCorp Vault** | Secrets management for credentials and API keys | BUSL (free tier) |

---

## 🗂️ Repository Structure

```
ecrime-homelab/
├── README.md
├── ARCHITECTURE.md
├── SECURITY.md
├── CONTRIBUTING.md
├── LEGAL.md
│
├── docs/
│   ├── setup-guide.md              # Full deployment walkthrough
│   ├── vm-specs.md                 # Hardware requirements per VM
│   ├── network-design.md           # VLAN topology and firewall rules
│   ├── forensic-soundness.md       # Evidence handling SOP
│   ├── chain-of-custody.md         # CoC template and procedures
│   └── certifications-map.md       # Tools → cert coverage map
│
├── infrastructure/
│   ├── proxmox/
│   │   ├── terraform/              # Proxmox VM provisioning (IaC)
│   │   └── cloud-init/             # VM templates and seed configs
│   ├── network/
│   │   ├── network-diagram.mermaid # Full topology diagram
│   │   ├── opnsense-config.xml     # Firewall ruleset template
│   │   ├── vlans.md                # VLAN table and purpose
│   │   └── wireguard/              # VPN config templates (no keys)
│   └── storage/
│       └── zfs-setup.sh            # ZFS evidence pool creation
│
├── vms/
│   ├── sift-remnux/
│   ├── tsurugi/
│   ├── flare-vm/
│   ├── velociraptor/
│   ├── cape-sandbox/
│   ├── sof-elk/
│   ├── thehive-cortex/
│   ├── misp-opencti/
│   ├── ms-cloud/
│   └── android-forensics/
│
├── ansible/
│   ├── site.yml                    # Master playbook
│   ├── inventory.ini.tmpl          # Inventory template
│   └── roles/                      # Per-VM hardening + setup roles
│
├── hunts/
│   ├── velociraptor/               # VQL hunt queries
│   ├── sigma-rules/                # Custom Sigma → SOF-ELK
│   └── yara-rules/                 # Malware family YARA signatures
│
├── workflows/
│   ├── live-response-sop.md
│   ├── deadbox-sop.md
│   ├── cloud-m365-sop.md
│   ├── android-mobile-sop.md
│   ├── malware-analysis-sop.md
│   └── crypto-tracing-sop.md
│
├── crypto-tracing/
│   ├── graphsense-setup.sh
│   ├── blocksci-setup.sh
│   └── wallet-pivot-templates.md
│
├── reporting/
│   ├── templates/
│   │   ├── forensic-report.md
│   │   ├── malware-report.md
│   │   └── executive-summary.md
│   └── pandoc-report-gen.sh
│
├── ctf/
│   ├── challenges/                 # Tool-indexed CTF write-ups
│   └── practice-images/            # Links to legal forensic images
│
└── .github/
    ├── ISSUE_TEMPLATE/
    │   ├── bug-report.yml
    │   └── tool-request.yml
    └── workflows/
        ├── ansible-lint.yml
        └── terraform-validate.yml
```

---

## ⚙️ Deployment Phases

| Phase | Scope | Duration |
|---|---|---|
| **Phase 1** — Foundation | Proxmox, OPNsense, VLAN fabric, ZFS NAS, WireGuard | Week 1 |
| **Phase 2** — DFIR Core | SIFT+REMnux, Tsurugi, Flare-VM, EZ Tools | Week 2 |
| **Phase 3** — Hunting & Detection | Velociraptor, Zeek+Suricata, SOF-ELK pipelines | Week 3 |
| **Phase 4** — Malware Lab | CAPE Sandbox, INetSim (isolated VLAN), YARA+Sigma | Week 4 |
| **Phase 5** — Intelligence & Case Mgmt | TheHive 4+Cortex, MISP, OpenCTI, Shuffle SOAR | Week 5 |
| **Phase 6** — Cloud & Mobile | MS Extractor+Analyzer, ROADtools, ALEAPP, MVT, Andriller | Week 6 |
| **Phase 7** — Hardening & Validation | Ansible hardening, audit log validation, CoC tests | Week 7 |

---

## 🖥️ Hardware Requirements

### Recommended (Full Stack)

| Component | Spec |
|---|---|
| CPU | 12 cores / 24 threads (Intel i9-13900 or AMD Ryzen 9 7950X) |
| RAM | 128 GB DDR5 |
| NVMe SSD | 2 TB (OS + active VMs) |
| HDD/NAS | 8 TB+ RAID-Z1 (evidence storage) |
| NIC | 2× 2.5 GbE (management + analysis) |

### Minimum (Phased / Budget)

| Component | Spec |
|---|---|
| CPU | 8 cores / 16 threads |
| RAM | 64 GB DDR4 |
| SSD | 1 TB NVMe |
| HDD | 4 TB (RAID-1 minimum) |

> **Phased build tip:** Run CAPE + INetSim only on demand using Proxmox snapshot/restore. Keep TheHive, MISP, and OpenCTI as a Docker Compose stack on a single VM to conserve RAM.

---

## 🔒 Forensic Soundness Controls

```
EVIDENCE INTEGRITY CHAIN
──────────────────────────────────────────────────────────
1. Acquisition   → SHA-256 + MD5 dual-hash on every ingest
2. Storage       → ZFS with immutable snapshots (append-only)
3. Access        → Read-only bind mounts for all analysis VMs
4. Audit         → All access events logged to SOF-ELK
5. Chain of      → Auto-generated per case via TheHive 4
   Custody          with timestamps and analyst attribution
6. Reporting     → Markdown → PDF via pandoc pipeline
──────────────────────────────────────────────────────────
```

See [forensic-soundness.md](docs/forensic-soundness.md) for full SOP.

---

## 🎓 Certification Coverage

| Certification | Tools Covered |
|---|---|
| **GCFE / GCFA** | SIFT, EZ Tools, Tsurugi, Autopsy |
| **GREM** | REMnux, Flare-VM, CAPE, INetSim |
| **GCTI** | MISP, OpenCTI, Velociraptor hunts |
| **GCFR** (Cloud) | MS Extractor Suite, ROADtools, SOF-ELK |
| **Cellebrite / Android** | ALEAPP, MVT, Andriller |
| **BTL1 / BTL2** | Full stack — SOC + DFIR + threat hunting |
| **eJPT / PNPT** | Flare-VM RE + Zeek/Suricata network analysis |

---

## 🚀 Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_ORG/ecrime-homelab.git
cd ecrime-homelab

# 2. Review and edit the inventory template
cp ansible/inventory.ini.tmpl ansible/inventory.ini
nano ansible/inventory.ini

# 3. Deploy infrastructure with Terraform
cd infrastructure/proxmox/terraform
terraform init
terraform plan
terraform apply

# 4. Run the master Ansible playbook
cd ../../../ansible
ansible-playbook -i inventory.ini site.yml

# 5. Verify deployment
ansible-playbook -i inventory.ini site.yml --tags verify
```

Full step-by-step: [docs/setup-guide.md](docs/setup-guide.md)

---

## 🤝 Contributing

Contributions welcome — VQL hunts, YARA rules, Sigma rules, SOPs, and CTF write-ups especially.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License — see [LICENSE](LICENSE).

Tools included retain their own licenses. See [docs/tool-licenses.md](docs/tool-licenses.md) for the full inventory.
