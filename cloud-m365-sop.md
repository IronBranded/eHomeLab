# SOP — Microsoft 365 / Azure Cloud Forensics

**Scope:** Incident response and forensic investigation of M365, Entra ID, and Azure  
**Tools:** MS Extractor Suite, MS Analyzer Suite, ROADtools, Hawk  
**VM:** MS Cloud VM (10.0.20.40) — RDP via WireGuard  
**Time estimate:** 2–6 hours for initial log collection

---

## Prerequisites

- Tenant ID of the target organisation
- Global Admin credentials OR delegated forensic account with `Security Reader` + `Audit Log` permissions
- PowerShell 7+ on MS Cloud VM

---

## Phase 1 — Connect and Collect (30–90 min)

### 1.1 RDP to MS Cloud VM

```bash
# From analyst workstation via WireGuard
xfreerdp /v:10.0.20.40 /u:analyst /p:'<password>' /w:1920 /h:1080
```

### 1.2 Run unified extraction script

```powershell
# In PowerShell on MS Cloud VM
cd C:\Tools
.\m365-extract.ps1 -TenantId "<tenant-id>" `
                   -StartDate (Get-Date).AddDays(-90) `
                   -EndDate (Get-Date)
```

This collects:
- Unified Audit Log (UAL) — 90 days
- Admin Audit Log
- Mailbox Audit Log
- MFA registration status
- User account list
- Entra ID conditional access policies
- Service principals and OAuth permissions

### 1.3 Run Hawk threat hunting

```powershell
# Start Hawk collection
Import-Module Hawk
Start-HawkTenantInvestigation -TenantId "<tenant-id>" `
                               -OutputDir "C:\Evidence\CloudForensics\Hawk"
```

---

## Phase 2 — ROADtools Enumeration (30 min)

```bash
# From SIFT workstation (Python tooling)
roadrecon gather --tenant-id <tenant-id> \
                 --output /opt/output/roadrecon-data.json

# Build ROADrecon web UI database
roadrecon auth -t <tenant-id>
roadrecon gather -d roadrecon.db
roadrecon gui   # Opens at http://localhost:5000
```

Key objects to enumerate:
- Service principals with high privilege roles
- Application registrations with broad API permissions
- OAuth2 permission grants
- Groups with privileged membership
- Guest users with unexpected access

---

## Phase 3 — UAL Analysis (30–60 min)

### 3.1 Parse with Microsoft Analyzer Suite

```powershell
cd C:\Tools\MicrosoftAnalyzer\Microsoft-Analyzer-Suite-main

# Parse UAL for suspicious operations
.\Invoke-MicrosoftAuditLogAnalyzer.ps1 `
  -InputPath "C:\Evidence\CloudForensics\<date>\UAL" `
  -OutputPath "C:\Evidence\CloudForensics\<date>\Analysis"
```

### 3.2 Key events to hunt

| EventID / Operation | Significance |
|---|---|
| `UserLoggedIn` from unusual country | Account compromise |
| `Add service principal` | Backdoor app registration |
| `Add app role assignment` | Privilege escalation |
| `Set-MsolUserPassword` | Password reset by attacker |
| `New-InboxRule` | Email exfiltration setup |
| `MailItemsAccessed` | Email snooping |
| `FileDownloaded` en masse | Data exfiltration |
| `TeamSettingChanged` | Teams channel exfiltration |

### 3.3 Ingest to SOF-ELK

```bash
# From SIFT workstation
scp analyst@10.0.20.40:"C:/Evidence/CloudForensics/*.json" \
    /mnt/evidence/cases/case-001/cloud/

# Ingest via Filebeat
filebeat -e -c /etc/filebeat/filebeat.yml
```

---

## Phase 4 — Findings and Reporting (30 min)

### 4.1 Create TheHive case

1. Create new case in TheHive: `http://10.0.40.20:9000`
2. Add observables: suspicious IPs, email addresses, app IDs, UPNs
3. Run Cortex enrichment
4. Link to MISP events if shared IOCs exist

### 4.2 Push IOCs to MISP

```python
# On SIFT
python3 /opt/scripts/push-to-misp.py \
  --iocs /mnt/evidence/cases/case-001/cloud/iocs.txt \
  --tlp amber \
  --case "M365 Compromise — Case 001"
```

### 4.3 Generate report

```bash
cp /opt/reporting/templates/forensic-report.md \
   /mnt/evidence/reports/case-001-cloud-forensics.md
# Edit report, then:
pandoc /mnt/evidence/reports/case-001-cloud-forensics.md \
       -o /mnt/evidence/reports/case-001-cloud-forensics.pdf
```
