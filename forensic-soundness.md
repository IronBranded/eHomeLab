# Forensic Soundness — Evidence Handling SOP

> This document defines the evidence handling procedures that ensure all digital evidence collected and analysed in this lab meets the standards required for legal admissibility and professional DFIR engagements.  
> Aligned with **ISO/IEC 27037:2012** and **ACPO Good Practice Guide**.

---

## 1. Core Principles

| Principle | Implementation |
|---|---|
| **Integrity** | SHA-256 + MD5 dual-hash on every item at point of acquisition |
| **Authenticity** | ZFS immutable snapshots — cryptographically verifiable state |
| **Continuity** | TheHive case timeline documents every analyst action |
| **Auditability** | All access events logged to SOF-ELK (tamper-evident) |
| **Minimisation** | Read-only NFS mounts — analysis VMs cannot write to NAS |

---

## 2. Evidence Acquisition

### 2.1 Disk Images

Always use a hardware or software write-blocker before acquiring:

```bash
# Preferred: dc3dd with dual hash
dc3dd if=/dev/sdX hash=sha256 hash=md5 \
  of=/mnt/evidence/acquisition/case-001/disk.dd \
  log=/mnt/evidence/acquisition/case-001/acquisition.log \
  2>&1 | tee /mnt/evidence/acquisition/case-001/dc3dd.log

# Alternative: ewfacquire (E01 format with metadata)
ewfacquire /dev/sdX \
  -t /mnt/evidence/acquisition/case-001/disk \
  -C "Case 001" -E "Examiner Name" -N "Notes here"
```

### 2.2 Memory Acquisition

On live Linux hosts:
```bash
# AVML — minimal footprint
avml /mnt/evidence/acquisition/case-001/memory.lime
sha256sum /mnt/evidence/acquisition/case-001/memory.lime
```

On live Windows hosts (via Velociraptor):
```
# VQL — collect memory via Velociraptor server UI or CLI
SELECT * FROM collect(artifacts=['Windows.Memory.Acquisition'])
```

### 2.3 Automatic Manifest Generation

The ZFS NAS runs an inotify watcher that automatically generates a SHA-256 + MD5 manifest whenever a file lands in `/srv/evidence/acquisition/`. The manifest is stored alongside the evidence and is itself immutable (read-only after creation).

To manually trigger:
```bash
ssh ansible@10.0.60.10
sudo generate-manifest /srv/evidence/acquisition/case-001/
```

---

## 3. Evidence Storage

### 3.1 ZFS Pool Structure

```
evidence/
├── acquisition/    ← Write-once; locked to read-only after ingest
├── cases/          ← Working copies (read-only NFS to VLAN 20)
├── malware/        ← Malware samples (read-only NFS to VLAN 20)
└── reports/        ← Final reports and manifests
```

### 3.2 Snapshot Schedule

| Frequency | Retention | Purpose |
|---|---|---|
| Hourly | 24 snapshots | Short-term recovery |
| Daily | 30 snapshots | Case-duration continuity |
| Weekly | 12 snapshots | Long-term integrity |

List current snapshots:
```bash
zfs list -t snapshot evidence
```

Verify pool integrity:
```bash
zpool scrub evidence && zpool status evidence
```

---

## 4. Chain of Custody

Every case in TheHive automatically generates a chain-of-custody log. Analysts must:

1. **Create a case in TheHive before touching any evidence**
2. **Log every significant action** as a task or case note with timestamp
3. **Attach evidence hashes** to the TheHive case as observables
4. **Document tool versions** used for each analysis step

### 4.1 Minimum Case Note Standard

Each case note must include:
- Date/time (UTC)
- Analyst name
- Action performed
- Tool and version used
- Hash of any file accessed or created
- Finding (if any)

### 4.2 Exporting a Chain-of-Custody Report

From TheHive:
```
Case → Export → PDF report
```

Or use the reporting pipeline:
```bash
# From SIFT workstation
cd /opt/reporting
./pandoc-report-gen.sh --case case-001 --output /mnt/evidence/reports/
```

---

## 5. Analysis Rules

| Rule | Reason |
|---|---|
| Never work directly on original evidence | Protect integrity |
| Always mount NFS as read-only | Enforced by NFS exports config |
| Never extract malware to analysis VLAN without hashing | Prevents untracked artefacts |
| Never connect detonation VLAN to internet | Air-gap is a security control |
| Always document tool outputs in TheHive | Continuity of record |
| Rotate encryption passphrases per case | Limit exposure |

---

## 6. Verification Checklist

Before closing any case, verify:

- [ ] All evidence items have SHA-256 + MD5 hashes recorded in TheHive
- [ ] ZFS snapshot taken at case close
- [ ] Chain-of-custody report exported and stored in `evidence/reports/`
- [ ] All tool outputs saved with corresponding hashes
- [ ] SOF-ELK audit trail reviewed for unexpected access events
- [ ] Acquisition dataset locked to `readonly=on` in ZFS
- [ ] All temporary working files removed from analysis VMs
