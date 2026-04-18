# Android Mobile Forensics SOP

> **Scope:** Android devices, APK analysis, spyware detection  
> **Workstation:** Android Forensics VM (10.0.20.50)  
> **Tools:** ALEAPP, MVT, Andriller CE, ADB

---

## Pre-Analysis Checklist

- [ ] Device received with documented chain of custody
- [ ] Device serial number photographed and logged in TheHive
- [ ] USB cable and write-blocker prepared (or ADB used with evidence awareness)
- [ ] Device in airplane mode — prevent remote wipe
- [ ] Analyst workstation connected to Android VM via WireGuard

---

## Step 1 — Device Triage and Identification

```bash
# Connect device and verify ADB sees it
adb devices -l

# Get device info
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.serialno

# Screenshot current state
adb shell screencap /sdcard/screen-$(date +%Y%m%d-%H%M%S).png
adb pull /sdcard/screen-*.png /opt/android-output/triage/
```

---

## Step 2 — Full Backup Acquisition

```bash
CASE_ID="CHANGEME"
OUTPUT="/opt/android-output/${CASE_ID}"
mkdir -p $OUTPUT

# ADB backup (partial — excludes some encrypted data)
adb backup -apk -shared -all -f ${OUTPUT}/backup-$(date +%Y%m%d).ab

# Hash the backup
sha256sum ${OUTPUT}/backup-*.ab | tee ${OUTPUT}/MANIFEST-SHA256.txt

# Copy key directories
adb pull /sdcard/ ${OUTPUT}/sdcard/
adb shell run-as com.android.providers.telephony cp \
  /data/data/com.android.providers.telephony/databases/mmssms.db \
  /sdcard/mmssms_tmp.db
adb pull /sdcard/mmssms_tmp.db ${OUTPUT}/
```

---

## Step 3 — ALEAPP Analysis

```bash
# Parse Android artifacts from backup or image
aleapp -t ab -i ${OUTPUT}/backup-*.ab -o ${OUTPUT}/aleapp-report/

# Or from a full filesystem image
aleapp -t fs -i /mnt/evidence/acquisition/${CASE_ID}-android/ \
  -o ${OUTPUT}/aleapp-report/

# Key outputs to review:
# - accounts_ce.db     → Google accounts
# - bugreport.db       → system logs
# - calls.db           → call history
# - contacts.db        → contacts
# - sms.db             → SMS/MMS
# - locations.db       → location history
```

---

## Step 4 — MVT Spyware Detection

```bash
# Download latest IOC indicators
mvt-android download-iocs --output /opt/mvt-venv/indicators/

# Check device for known spyware indicators
mvt-android check-adb \
  --iocs /opt/mvt-venv/indicators/ \
  --output ${OUTPUT}/mvt-report/ \
  --serial $(adb devices | grep device | head -1 | awk '{print $1}')

# If you have a full filesystem image
mvt-android check-fs \
  --iocs /opt/mvt-venv/indicators/ \
  --output ${OUTPUT}/mvt-report/ \
  /mnt/evidence/acquisition/${CASE_ID}-android/

# Review MVT timeline and detections
cat ${OUTPUT}/mvt-report/timeline.json | python3 -m json.tool | grep -A5 '"detected"'
```

---

## Step 5 — Andriller CE — App Database Extraction

```bash
# Extract and decode all app databases
andriller -o ${OUTPUT}/andriller-report/ \
  -d $(adb devices | grep device | head -1 | awk '{print $1}')

# WhatsApp specifically
andriller --app WhatsApp \
  -o ${OUTPUT}/whatsapp/ \
  -d $(adb devices | grep device | head -1 | awk '{print $1}')
```

---

## Step 6 — APK Analysis (if malicious app suspected)

```bash
# Pull suspect APK
adb shell pm list packages -f | grep <suspect_app_name>
adb pull /data/app/<suspect_package>/ ${OUTPUT}/apk/

# Static analysis
apktool d ${OUTPUT}/apk/base.apk -o ${OUTPUT}/apk-decoded/
apkleaks -f ${OUTPUT}/apk/base.apk -o ${OUTPUT}/apk-leaks.txt

# Check for hardcoded secrets / C2
grep -r "http\|https\|api_key\|password\|token" ${OUTPUT}/apk-decoded/smali/
```

---

## Step 7 — Document and Export

```bash
# Generate case manifest
generate-manifest ${OUTPUT}/

# Copy to evidence NAS
cp -r ${OUTPUT}/ /mnt/evidence/cases/${CASE_ID}/android/

# Update TheHive with IOCs found
# Add observables: phone numbers, email addresses, domains, IPs from MVT report
```
