# Legal Notice

## Purpose and Intended Use

ECrime Homelab is an open-source infrastructure project designed exclusively for:

- **Authorised digital forensics and incident response** on systems you own or have explicit written permission to investigate
- **Malware research** using samples obtained through legitimate means (MalwareBazaar, VirusTotal, coordinated disclosure)
- **Security education and training** in controlled, isolated lab environments
- **CTF (Capture the Flag) competitions** and certification exam preparation
- **Academic security research** with appropriate institutional oversight

---

## Prohibited Uses

The following uses are strictly prohibited:

- Investigating, accessing, or collecting evidence from systems, devices, or accounts without explicit legal authorisation
- Detonating malware samples that have not been obtained through legitimate research channels
- Using crypto tracing capabilities against wallets or transactions without lawful authorisation
- Using OSINT or network reconnaissance tools against targets without authorisation
- Using live response or EDR capabilities (Velociraptor) against endpoints you do not own or administer
- Any activity that violates applicable local, national, or international laws

---

## Jurisdiction and Compliance

Users are solely responsible for ensuring their use of this lab complies with all applicable laws in their jurisdiction, including but not limited to:

| Jurisdiction | Relevant Law |
|---|---|
| United States | Computer Fraud and Abuse Act (18 U.S.C. § 1030), Electronic Communications Privacy Act |
| European Union | Directive on Attacks Against Information Systems (2013/40/EU), GDPR |
| United Kingdom | Computer Misuse Act 1990, Investigatory Powers Act 2016 |
| Canada | Criminal Code Part VI (ss. 184–196), Personal Information Protection Act |
| Australia | Criminal Code Act 1995 (Part 10.7), Privacy Act 1988 |

This list is not exhaustive. Always obtain qualified legal advice before conducting investigations.

---

## Evidence Handling

If you use this lab for real investigations:

- Maintain chain of custody documentation for all acquired evidence
- Store evidence on the ZFS NAS with immutable snapshots as designed
- Follow your jurisdiction's rules regarding evidence admissibility
- Do not modify original evidence — the lab architecture enforces read-only mounts by design
- Consult a qualified forensic examiner or legal counsel before presenting evidence in legal proceedings

---

## Malware Handling

- The CAPE Sandbox VLAN 30 detonation environment is air-gapped by design — do not attempt to modify routing rules to allow malware egress
- Never detonate ransomware, wipers, or destructive payloads outside an isolated environment
- Follow responsible disclosure practices for any vulnerabilities discovered during research
- Report criminal activity discovered during investigations to the appropriate law enforcement authorities

---

## Disclaimer

THIS SOFTWARE AND DOCUMENTATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. THE AUTHORS AND CONTRIBUTORS ACCEPT NO LIABILITY FOR:

- Damage to systems, data, or infrastructure resulting from use of this lab
- Legal consequences arising from misuse
- Actions taken by third parties using this infrastructure
- Evidence that is inadmissible due to improper collection or handling procedures

Use at your own risk. The security community is trusted to use these tools responsibly.

---

## Tool Licenses

All tools deployed by this infrastructure retain their original licenses. Key licenses in use:

| Tool | License |
|---|---|
| SIFT Workstation | Apache 2.0 / various |
| REMnux | Custom — see remnux.org/docs/legal |
| Velociraptor | Apache 2.0 |
| CAPE Sandbox | GPL-2.0 |
| INetSim | GPL-2.0 |
| TheHive 4 | AGPL-3.0 |
| Cortex | AGPL-3.0 |
| MISP | AGPL-3.0 |
| OpenCTI | Apache 2.0 |
| Shuffle | AGPL-3.0 |
| SOF-ELK | See SANS — philhagen/sof-elk |
| Zeek | BSD-3-Clause |
| Suricata | GPL-2.0 |
| MVT | Apache 2.0 |
| ALEAPP | MIT |
| Andriller CE | Apache 2.0 |
| GraphSense | MIT |
| BlockSci | Apache 2.0 |
| SpiderFoot | MIT |
| Flare-VM | Apache 2.0 |
| ROADtools | MIT |
| Microsoft Extractor Suite | MIT |
| HashiCorp Vault | BUSL-1.1 (free for non-production) |
| OPNsense | BSD-2-Clause |

This infrastructure project itself is licensed under the MIT License — see [LICENSE](LICENSE).
