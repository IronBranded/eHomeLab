# Security Policy

## Overview

ECrime Homelab is a research and training environment that handles malware, forensic evidence, and sensitive investigation data. This document covers security practices for the lab itself and responsible disclosure for this repository.

---

## Supported Versions

| Component | Maintained |
|---|---|
| Ansible roles | ✅ Latest main branch |
| Terraform configs | ✅ Latest main branch |
| VQL hunt library | ✅ Latest main branch |
| YARA / Sigma rules | ✅ Latest main branch |
| Documentation | ✅ Latest main branch |

---

## Reporting a Vulnerability

If you discover a security vulnerability in this repository — such as a hardcoded credential, an insecure default configuration, a role that introduces a privilege escalation path, or a network design flaw — please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

### Reporting process

1. Open a [GitHub Security Advisory](https://github.com/YOUR_ORG/ecrime-homelab/security/advisories/new) (private disclosure)
2. Include:
   - Description of the vulnerability
   - Affected file(s) and line numbers
   - Steps to reproduce or proof of concept
   - Suggested fix if you have one
3. You will receive acknowledgement within 72 hours
4. A fix will be published within 14 days for critical issues, 30 days for others

---

## Lab Security Architecture

### Network isolation

- **VLAN 30 (Detonation)** is completely air-gapped — zero routing to any other VLAN. OPNsense enforces this at the firewall level. Malware in this zone cannot reach the internet or any other VM.
- **VLAN 60 (Evidence NAS)** exports are read-only to all analysis VMs. Evidence cannot be modified by any VM other than the designated acquisition host.
- All inter-VLAN traffic is logged to SOF-ELK on VLAN 50.

### Secrets management

- All credentials are stored in `ansible/group_vars/vault.yml`, encrypted with `ansible-vault`
- The vault file is in `.gitignore` and must never be committed
- HashiCorp Vault (10.0.10.11) provides dynamic secrets for service integrations
- No credentials are hardcoded in any playbook, template, or config file

### Analyst access

- Remote access is exclusively via WireGuard VPN — no direct internet exposure
- All SSH uses Ed25519 keys; password authentication is disabled on all hosts
- Privilege escalation is logged via auditd and forwarded to SOF-ELK

### Evidence integrity

- All acquired evidence is hashed (SHA-256 + MD5) on ingest via the `generate-manifest` script
- ZFS immutable snapshots prevent modification of acquired evidence
- All access to the NAS is logged with analyst identity and timestamp

---

## Known Intentional Risks

The following are accepted risks for a research lab environment and should be understood before deployment:

| Risk | Reason Accepted | Mitigation |
|---|---|---|
| Self-signed TLS certificates | Lab environment — no public CA | VPN-only access |
| Jupyter notebook has no auth token | Management VLAN access only | UFW restricts to `10.0.10.0/24` |
| SpiderFoot has no auth by default | VPN-only access | UFW restricts to `10.0.10.0/24` + `10.0.20.0/24` |
| CAPE runs with broad KVM privileges | Required for malware detonation | Air-gapped VLAN 30 |
| Winlogbeat ships raw Windows events | Required for DFIR telemetry | Encrypted Beats protocol to SOF-ELK |

---

## Legal Notice

This lab is strictly for **authorised research, education, and lawful investigations only**.

- Never detonate malware samples obtained without authorisation
- Never use crypto tracing tools against wallets without legal authorisation
- Never use live response tools against systems you do not own or have explicit permission to investigate
- Comply with all applicable laws in your jurisdiction

See [LEGAL.md](LEGAL.md) for the full legal notice.
