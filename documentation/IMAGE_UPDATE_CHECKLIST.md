# Base Image Update & Security Validation Checklist

**Last Updated:** January 14, 2026  
**Current Base Image:** bitnami/node:latest (v24.13.0)

## 🔄 Weekly Update Process

### 1. Pull Latest Hardened Images
```bash
# Update the primary base image
docker pull bitnami/node:latest

# (Optional) Update all extended images
docker pull bitnami/python:3.12
docker pull bitnami/nginx:1.27
docker pull bitnami/postgresql:16
# ... add others as needed
```

### 2. Verify Image Versions
```bash
# Check Node.js version
docker image inspect bitnami/node:latest --format '{{index .Config.Labels "org.opencontainers.image.version"}}'

# Check image creation date
docker image inspect bitnami/node:latest --format '{{index .Config.Labels "org.opencontainers.image.created"}}'

# Expected output (as of Jan 14, 2026):
# Version: 24.13.0
# Created: 2026-01-13T17:57:25Z
```

### 3. Run Security Scans
```bash
cd /Users/rnelson/Desktop/Side_Projects/comprehensive-security-architecture

# Run full security scan on your project
./scripts/shell/run-trivy-scan.sh /path/to/your/project

# Or scan just the base images
./scripts/shell/run-trivy-scan.sh base
```

### 4. Review Scan Results
```bash
# Check the latest scan directory
ls -lt scans/ | head -5

# Review consolidated findings
cat scans/<latest-scan-dir>/security-findings-summary.json | jq '.summary'

# Check critical and high vulnerabilities
cat scans/<latest-scan-dir>/security-findings-summary.json | jq '.critical_findings, .high_findings'
```

## 🎯 Key Metrics to Monitor

### Vulnerability Thresholds
- **CRITICAL**: 0 (immediate action required)
- **HIGH**: ≤ 5 (review and plan remediation)
- **MEDIUM**: ≤ 20 (monitor and update when fixes available)
- **LOW**: Monitor only

### Image Freshness
- Base images should be ≤ 7 days old
- If image is > 14 days old, pull latest immediately
- Bitnami typically releases updates every 1-3 days

## 🔍 Common Vulnerabilities in Node Images

### Current Known Issues (Jan 2026)
Based on recent scans, watch for:

1. **glob (npm package)** - Command injection vulnerabilities
   - CVE-2025-64756 (HIGH)
   - Fix: Update to glob 10.5.0 or 11.1.0+
   - Impact: Bundled with npm in Node image

2. **node-tar** - Race condition vulnerabilities
   - CVE-2025-64118 (MEDIUM)
   - Fix: Update to latest node-tar version
   - Impact: Bundled with npm

3. **pip (Python)** - Tar extraction issues
   - CVE-2025-8869 (MEDIUM)
   - Impact: Python is bundled for node-gyp builds

### Remediation Strategy
Most vulnerabilities in Bitnami images come from:
- Bundled tools (npm, pip) that ship with the runtime
- System packages in the base OS (Photon OS)

**Action Items:**
1. Pull latest image (often already patched)
2. If still vulnerable, check if your code actually uses the vulnerable feature
3. Consider risk vs. impact for bundled tools not directly used
4. Report persistent issues to Bitnami: https://github.com/bitnami/containers/issues

## 📊 Quick Health Check

Run this one-liner to check your current setup:
```bash
echo "=== Base Image Health Check ===" && \
docker image inspect bitnami/node:latest --format \
'Image: {{.RepoTags}}
Created: {{index .Config.Labels "org.opencontainers.image.created"}}
Version: {{index .Config.Labels "org.opencontainers.image.version"}}
Size: {{.Size}}' && \
echo "" && \
echo "Last Scan:" && \
ls -lt scans/ | head -2 | tail -1 && \
echo "" && \
echo "Latest Scan Summary:" && \
cat $(ls -t scans/*/security-findings-summary.json | head -1) | jq -r '"Critical: \(.summary.total_critical) | High: \(.summary.total_high) | Medium: \(.summary.total_medium)"'
```

## 🚀 Production Deployment Recommendations

### For Development/Testing
```dockerfile
FROM bitnami/node:latest
```
✅ Gets latest security patches automatically

### For Production
```dockerfile
FROM bitnami/node:24.13.0
# or use digest for immutability
FROM bitnami/node@sha256:bfd08ce795e22fb80364230b74d4295914805e939fceeeb6e087846ec697a07c
```
✅ Reproducible builds
✅ Controlled updates after testing

## 📅 Maintenance Schedule

- **Daily**: Check for critical CVEs in monitoring tools
- **Weekly**: Pull latest images and run scans
- **Monthly**: Review all medium/low vulnerabilities
- **Quarterly**: Audit all approved base images list
- **Yearly**: Review and update base image strategy

## 🔗 Resources

- **Bitnami Security Advisories**: https://github.com/bitnami/containers/security/advisories
- **CVE Database**: https://nvd.nist.gov/
- **Trivy Docs**: https://aquasecurity.github.io/trivy/
- **Grype Docs**: https://github.com/anchore/grype

## 📝 Update Log

| Date | Image Version | Action Taken | Vulnerabilities |
|------|---------------|--------------|-----------------|
| 2026-01-14 | 24.13.0 | Updated to latest | 0 Critical, 10 High |
| 2025-12-04 | 24.11.1 | Previous version | 0 Critical, 12 High |

---

**Next Review Date:** January 21, 2026
