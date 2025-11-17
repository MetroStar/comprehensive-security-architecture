# PowerShell Scan Directory Update Status

**Date:** November 17, 2025  
**Current Progress:** 3 of 13 files completed

## ✅ Completed Files

1. **Scan-Directory-Template.ps1** - Core template (NEW)
2. **run-anchore-scan.ps1** - Anchore placeholder (NEW)
3. **run-sbom-scan.ps1** - SBOM generation (NEW)

## 📋 Pending Updates (8 Tool Scripts)

These scripts exist but need scan directory template integration:

1. run-checkov-scan.ps1
2. run-clamav-scan.ps1
3. run-grype-scan.ps1
4. run-helm-build.ps1
5. run-sonar-analysis.ps1
6. run-trivy-scan.ps1
7. run-trufflehog-scan.ps1
8. run-xeol-scan.ps1

### Update Pattern for Each Script

#### Step 1: Add Template Import (after param block)
\`\`\`powershell
# Initialize scan environment using scan directory approach
\$ScriptDir = Split-Path -Parent \$MyInvocation.MyCommand.Path

# Source the scan directory template
. "\$ScriptDir\Scan-Directory-Template.ps1"

# Initialize scan environment for [toolname]
\$scanEnv = Initialize-ScanEnvironment -ToolName "[toolname]"
\`\`\`

#### Step 2: Add Scan ID Extraction
\`\`\`powershell
# Extract scan information
if (\$env:SCAN_ID) {
    \$SCAN_ID = \$env:SCAN_ID
}
else {
    \$targetPath = if (\$env:TARGET_DIR) { \$env:TARGET_DIR } else { Get-Location }
    \$TARGET_NAME = Split-Path -Leaf \$targetPath
    \$USERNAME = if (\$env:USERNAME) { \$env:USERNAME } else { \$env:USER }
    \$TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    \$SCAN_ID = "\${TARGET_NAME}_\${USERNAME}_\${TIMESTAMP}"
}
\`\`\`

#### Step 3: Remove Hardcoded Paths
Remove or comment out these lines:
\`\`\`powershell
# REMOVE:
\$OutputDir = "..\..\reports\grype-reports"
\$ScanLog = Join-Path \$OutputDir "grype-scan.log"
New-Item -ItemType Directory -Force -Path \$OutputDir | Out-Null
\`\`\`

#### Step 4: Use Global Variables
Replace `\$OutputDir` with `\$OUTPUT_DIR` (from template)
Replace `\$ScanLog` with `\$SCAN_LOG` (from template)

#### Step 5: Add Finalization (before exit)
\`\`\`powershell
Complete-ScanResults -ToolName "[toolname]"
exit 0
\`\`\`

## 🔴 Critical Orchestrator Updates

### run-target-security-scan.ps1
Needs major update to:
1. Create SCAN_DIR for each scan
2. Export \$env:SCAN_DIR to child scripts
3. Update report path references
4. Match bash orchestrator logic

### consolidate-security-reports.ps1
Needs update to:
1. Read from \$env:SCAN_DIR structure
2. Output to \$SCAN_DIR/consolidated-reports
3. Match bash consolidation script

## 📄 Additional Scripts Needed

### generate-scan-findings-summary.ps1
Port from bash to create security findings summary in PowerShell.

## 🛠️ Automation Tool Created

**Update-ToolScripts-ScanDirectory.ps1** - Batch update script (not yet run)

This script can automatically update all 8 tool scripts if run on a Windows machine with PowerShell.

## ⏱️ Time Estimate

- Tool scripts: ~2 hours manual, ~15 min with automation script
- Orchestrator: ~45 min
- Consolidation: ~30 min  
- Findings summary: ~30 min
- Testing: ~1 hour

**Total:** ~4-5 hours for complete parity

## 🎯 Priority Recommendation

If time-limited, update in this order:
1. run-target-security-scan.ps1 (orchestrator)
2. Tool scripts (batch via automation)
3. consolidate-security-reports.ps1
4. generate-scan-findings-summary.ps1
