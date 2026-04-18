# Dead-Box Forensics SOP

> **Scope:** Disk images, memory dumps, offline analysis  
> **Evidence types:** E01/RAW disk images, LiME/raw memory dumps  
> **Workstation:** SIFT + REMnux (10.0.20.10)

---

## Pre-Analysis Checklist

- [ ] Evidence received on NAS at `/mnt/evidence/acquisition/`
- [ ] Hash verified against acquisition manifest: `sha256sum -c HASHES.txt`
- [ ] TheHive case referenced — log analyst name and start time
- [ ] SIFT workstation — evidence mount verified read-only: `findmnt /mnt/evidence`

---

## Step 1 — Verify Evidence Integrity

```bash
# On SIFT workstation
cd /mnt/evidence/acquisition/

# Verify all hashes
sha256sum -c MANIFEST-SHA256.txt

# For E01 images
ewfverify <casename>.E01

# Document result in TheHive as task log entry
```

---

## Step 2 — Disk Image Examination

### Mount the image (read-only, never write)

```bash
# Identify partition layout
mmls <casename>.E01

# Mount NTFS partition (offset from mmls output, multiply sectors × 512)
sudo ewfmount <casename>.E01 /mnt/ewf
sudo mount -o ro,loop,offset=<offset> /mnt/ewf/ewf1 /mnt/disk

# Verify read-only
findmnt /mnt/disk | grep -c "ro,"
```

### Super-timeline generation

```bash
# Build Plaso timeline (run from SIFT, write to NAS output)
log2timeline.py \
  --storage-file /mnt/evidence/cases/${CASE_ID}/timeline.plaso \
  --timezone UTC \
  /mnt/disk

# Sort and filter
psort.py \
  -o l2tcsv \
  -w /mnt/evidence/cases/${CASE_ID}/timeline.csv \
  /mnt/evidence/cases/${CASE_ID}/timeline.plaso
```

### Key artifact locations (Windows)

```bash
# Registry hives
/mnt/disk/Windows/System32/config/{SYSTEM,SOFTWARE,SAM,SECURITY}
/mnt/disk/Users/*/NTUSER.DAT

# Event logs
/mnt/disk/Windows/System32/winevt/Logs/

# Prefetch
/mnt/disk/Windows/Prefetch/

# MFT (NTFS filesystem journal)
/mnt/disk/$MFT
```

---

## Step 3 — Registry Analysis (EZ Tools)

```bash
# Parse all registry hives
eztools RECmd -d /mnt/disk/Windows/System32/config \
  --bn /opt/eztools/BatchExamples/RECmd_batch_MC.reb \
  --csv /mnt/evidence/cases/${CASE_ID}/registry/

# UserAssist (program execution)
eztools RECmd -d /mnt/disk/Users/*/NTUSER.DAT \
  --kn "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist" \
  --csv /mnt/evidence/cases/${CASE_ID}/registry/userassist/
```

---

## Step 4 — Memory Analysis (Volatility 3)

```bash
cd /mnt/evidence/acquisition/
DUMP="<casename>-memory.raw"

# Process list with parent chain
vol -f $DUMP windows.pslist.PsList

# Network connections
vol -f $DUMP windows.netstat.NetStat

# Detect injected code
vol -f $DUMP windows.malfind.Malfind \
  --dump-dir /mnt/evidence/cases/${CASE_ID}/malfind/

# Extract DLLs from suspicious processes
vol -f $DUMP windows.dlllist.DllList --pid <suspect_pid>

# Credential artifacts
vol -f $DUMP windows.hashdump.HashDump
```

---

## Step 5 — YARA Scanning

```bash
# Scan memory dump against all rules
yara -r /opt/yara-rules/index.yar \
  /mnt/evidence/acquisition/<casename>-memory.raw \
  | tee /mnt/evidence/cases/${CASE_ID}/yara-memory-hits.txt

# Scan disk image
yara -r /opt/yara-rules/index.yar \
  /mnt/disk/ \
  | tee /mnt/evidence/cases/${CASE_ID}/yara-disk-hits.txt
```

---

## Step 6 — Document Findings

1. Export all CSV outputs to `/mnt/evidence/cases/${CASE_ID}/`
2. Generate SHA-256 manifest of all case outputs: `generate-manifest /mnt/evidence/cases/${CASE_ID}/`
3. Import timeline into Timesketch for collaborative review
4. Update TheHive case — add observables (IOCs), close completed tasks
5. Draft findings in `reporting/templates/forensic-report.md`
