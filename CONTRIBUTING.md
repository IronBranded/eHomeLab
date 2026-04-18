# Contributing to ECrime Homelab

Thank you for contributing. This project exists to build a comprehensive, open-source DFIR/malware analysis lab that the community can use and improve together.

---

## Before You Contribute

### Non-negotiable requirements

Every contribution must satisfy these:

1. **100% open source** — no tool, role, or dependency may require a paid subscription for core functionality. Free tiers that become paid for more data are not acceptable.
2. **No credentials in code** — use `{{ vault_* }}` variables for all secrets. Never hardcode IPs, passwords, API keys, or tokens.
3. **Forensically sound** — nothing should modify evidence. Any tool that writes to the evidence NAS must only do so via the designated acquisition path.
4. **Idempotent** — Ansible roles must be safe to run multiple times. Use `creates:`, `state: present`, and `when:` guards.

---

## Types of Contributions Welcome

| Type | Description |
|---|---|
| 🐛 Bug fixes | Broken roles, wrong template variables, incorrect task logic |
| 🔧 New Ansible roles | New VM configurations matching scope |
| 🏹 VQL hunts | Velociraptor hunt queries for Windows threat hunting |
| 🔍 Sigma rules | Detection rules for SOF-ELK / Elasticsearch |
| 🦠 YARA rules | Malware family signatures for CAPE + SIFT |
| 📋 SOPs / Workflows | New investigation procedure documents |
| 📖 Docs | Setup guide improvements, clarifications, corrections |
| 🔬 CTF write-ups | Tool-indexed walkthroughs referencing lab tools |

---

## Contribution Workflow

```bash
# 1. Fork the repository
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/ecrime-homelab.git
cd ecrime-homelab

# 3. Create a branch
git checkout -b feature/add-zeek-dns-hunt

# 4. Make your changes
# 5. Test locally (see Testing below)

# 6. Commit with a clear message
git add .
git commit -m "hunts: add Zeek DNS tunnelling detection VQL"

# 7. Push and open a PR
git push origin feature/add-zeek-dns-hunt
```

---

## Ansible Role Standards

New roles must follow this structure:

```
roles/<role_name>/
├── tasks/main.yml       # All tasks — idempotent
├── defaults/main.yml    # Sensible defaults — no secrets
├── handlers/main.yml    # Service restart handlers
└── templates/           # Jinja2 .j2 files — no hardcoded values
```

**Task naming convention:** `"<role_prefix> | <action description>"`

```yaml
# Good
- name: "velociraptor | Deploy systemd service unit"

# Bad
- name: Deploy service
```

**Required for every role:**
- UFW rules that restrict service access to appropriate VLANs only
- Rsyslog or Filebeat forwarding configured to ship logs to SOF-ELK
- Evidence mounts must use `ro,` (read-only) NFS options

---

## VQL Hunt Standards

File location: `hunts/velociraptor/<hunt-name>.vql`

Required header block:

```vql
/*
 * Hunt: <Hunt Name>
 * Description: <What it detects>
 * MITRE ATT&CK: <Tactic> / <Technique ID>
 * Author: <GitHub username>
 * Tested: Velociraptor >= 0.72
 */
```

---

## Sigma Rule Standards

File location: `hunts/sigma-rules/<rule-name>.yml`

All rules must include:
- `title`, `id` (UUID), `status: experimental` or `stable`
- `logsource` specifying the correct product/category
- `tags` with MITRE ATT&CK references
- `falsepositives` section

---

## YARA Rule Standards

File location: `hunts/yara-rules/<family-name>.yar`

Requirements:
- Rules must compile cleanly: `yarac <rule.yar> /dev/null`
- Include `meta` block with `description`, `author`, `date`, `hash` of reference sample
- Minimum 3 unique strings or a reliable byte pattern

---

## Testing Before Submitting

```bash
# Ansible lint
pip install ansible-lint
cd ansible
ansible-lint site.yml

# Terraform validate
cd infrastructure/proxmox
terraform init -backend=false
terraform validate
terraform fmt -check

# YARA syntax
yarac hunts/yara-rules/*.yar /dev/null

# Sigma syntax
pip install sigma-cli
sigma check hunts/sigma-rules/*.yml
```

CI will also run these automatically on your PR.

---

## Commit Message Format

```
<type>(<scope>): <short description>

Types: feat, fix, docs, hunt, yara, sigma, ci, refactor
Scope: ansible, terraform, hunts, workflows, docs

Examples:
  feat(ansible): add opencti connector-misp integration
  fix(terraform): correct CAPE nested-virt cpu flag
  hunt(vql): add credential dumping via LSASS detection
  docs(setup-guide): add WireGuard bootstrap steps
```

---

## Code of Conduct

Be constructive, be respectful, and keep contributions focused on making the lab better. This is a technical project for the security research community.
