# Live Response SOP

> **Scope:** Windows endpoints, Linux servers  
> **Evidence:** Memory dump, running process list, network connections, registry (volatile)  
> **Standard:** ISO/IEC 27037 — identification, collection, acquisition, preservation

---

## Pre-Response Checklist

- [ ] Case opened in TheHive with severity and classification
- [ ] Legal authorisation confirmed and documented in case
- [ ] Chain of custody log started (analyst name, date/time UTC, system details)
- [ ] WireGuard VPN active — accessing lab from analyst workstation
- [ ] Velociraptor client confirmed online on target host

---

## Step 1 — Scope and Triage (0–15 min)

**Goal:** Confirm compromise, determine scope, decide collect-now vs shutdown.

```vql
-- Run from Velociraptor GUI — Hunt → New Hunt → Paste VQL
SELECT Fqdn, OS, Architecture, Hostname, MACAddresses
FROM info()
```

Decision tree:

- Active ransomware encrypting? → **Isolate immediately, image memory first (Step 2)**
- Suspected exfiltration in progress? → **Capture memory + network state, then isolate**
- Malware dormant / investigation? → **Full collection before any action**

---

## Step 2 — Memory Acquisition (collect first, always)

### Windows (via Velociraptor)

```vql
SELECT * FROM Artifact.Windows.Memory.Acquisition(
  destination="\\\\10.0.60.10\\evidence\\acquisition\\%HOSTNAME%-%timestamp%.raw"
)
```

### Linux (via AVML on SIFT)

```bash
# SSH to target or run from Velociraptor
sudo avml /mnt/evidence/acquisition/$(hostname)-$(date +%Y%m%d-%H%M%S).lime

# Hash immediately
sha256sum /mnt/evidence/acquisition/*.lime | tee /mnt/evidence/acquisition/HASHES.txt
```

---

## Step 3 — Volatile State Collection

```vql
-- Velociraptor — collect all critical volatile artifacts in one flow
SELECT * FROM Artifact.Windows.KapeFiles.Targets(
  _BasicCollection=true,
  _Browsers=true,
  _EventLogs=true,
  _Registry=true,
  _Prefetch=true,
  _LNKFilesAndJumpLists=true,
  _WebBrowsers=true,
  output="\\\\10.0.60.10\\evidence\\acquisition\\%HOSTNAME%-kape-%timestamp%"
)
```

Supplement with targeted hunts:

```vql
-- Active network connections
SELECT Pid, Name, Status, Laddr, Raddr, FamilyString, TypeString
FROM netstat()
WHERE Status = "ESTABLISHED" OR Status = "LISTEN"
ORDER BY Pid

-- Running processes with parent chain
SELECT Pid, Ppid, Name, CommandLine, Exe, CreateTime, Username
FROM pslist()
ORDER BY Ppid, Pid

-- Scheduled tasks (common persistence)
SELECT Name, Command, Arguments, ComHandler, Enabled, NextRunTime
FROM scheduled_tasks()
WHERE Enabled = true
```

---

## Step 4 — Isolation

Only after all volatile data is captured:

```bash
# Via OPNsense — block target IP immediately
# Firewall → Rules → Add block rule for src/dst = <target IP>

# Or via Velociraptor responder
SELECT * FROM Artifact.Windows.Remediation.NetworkIsolation()
```

Document isolation time in TheHive case timeline.

---

## Step 5 — Hand-off to Dead-box Analysis

1. Copy memory dump hash to TheHive case observables
2. Assign dead-box analysis task to next analyst
3. Reference: `workflows/deadbox-sop.md`
4. Update case status: `In Progress → Evidence Collected`
