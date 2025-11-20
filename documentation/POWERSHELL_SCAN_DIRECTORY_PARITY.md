# PowerShell Scan Directory Parity - Implementation Summary

**Date:** November 17, 2025  
**Status:** In Progress

## Completed

1. ✅ **Scan-Directory-Template.ps1** - PowerShell version of scan directory template
2. ✅ **run-anchore-scan.ps1** - PowerShell version of Anchore placeholder

## Remaining Work

### Critical Scripts (Need Creation)
- [ ] **run-sbom-scan.ps1** - SBOM generation (complex, uses Syft)

### Update Existing Scripts (Need Scan Directory Support)
The following 8 PowerShell scripts exist but need to be updated to use the scan directory template:

1. [ ] run-checkov-scan.ps1
2. [ ] run-clamav-scan.ps1
3. [ ] run-grype-scan.ps1
4. [ ] run-helm-build.ps1
5. [ ] run-sonar-analysis.ps1
6. [ ] run-trivy-scan.ps1
7. [ ] run-trufflehog-scan.ps1
8. [ ] run-xeol-scan.ps1

### Orchestrator & Analysis Scripts
- [ ] **run-target-security-scan.ps1** - Main orchestrator (needs scan directory support)
- [ ] **consolidate-security-reports.ps1** - Report consolidation (needs to read from scan dirs)
- [ ] **generate-scan-findings-summary.ps1** - Findings summary (port from bash)

## Required Changes for Each Tool Script

Each PowerShell tool script needs these updates:

### 1. Add Template Import (at top of script)
```powershell
# Source the scan directory template
. "$ScriptDir\Scan-Directory-Template.ps1"

# Initialize scan environment for [ToolName]
$scanEnv = Initialize-ScanEnvironment -ToolName "[toolname]"
```

### 2. Replace Hardcoded Paths
```powershell
# OLD:
$OUTPUT_DIR = Join-Path $ReportsRoot "reports" "$ToolName-reports"
$SCAN_LOG = Join-Path $OUTPUT_DIR "$SCAN_ID-$ToolName-scan.log"

# NEW:
# (Paths are set by Initialize-ScanEnvironment, use $OUTPUT_DIR and $SCAN_LOG directly)
```

### 3. Use Template Functions for Results
```powershell
# For creating result file paths:
$resultsFile = New-ResultFilePath -ToolName "grype" -ResultType "results" -Extension "json"

# At end of script:
Complete-ScanResults -ToolName "grype"
```

## PowerShell vs Bash Differences

### Environment Variables
- **Bash:** `$SCAN_DIR`, `$SCAN_ID`, `$TARGET_DIR`
- **PowerShell:** `$env:SCAN_DIR`, `$env:SCAN_ID`, `$env:TARGET_DIR`

### Path Separators
- **Bash:** Forward slashes (`/`)
- **PowerShell:** Backslashes (`\`) on Windows, forward on Unix

### Symlinks
- **Bash:** `ln -sf` works everywhere
- **PowerShell:** Requires admin rights on Windows, use fallback to Copy-Item

## Testing Requirements

After updates, test each script:
1. Standalone execution (no SCAN_DIR set)
2. Orchestrated execution (SCAN_DIR set by parent)
3. Verify output goes to scan directory
4. Verify symlinks created in reports directory

## Automation Approach

Rather than manually updating each script, consider:
1. Create update-powershell-for-scan-directory.ps1
2. Script reads each tool file
3. Detects output directory assignments
4. Injects template imports and function calls
5. Updates all 8 files automatically

## Priority Order

1. **High:** run-target-security-scan.ps1 (orchestrator)
2. **High:** consolidate-security-reports.ps1  
3. **Medium:** Individual tool scripts (grype, trivy, etc.)
4. **Low:** run-sbom-scan.ps1 (complex, can be done last)
5. **Low:** generate-scan-findings-summary.ps1

## Notes

- PowerShell scripts haven't been actively used (last update Nov 12)
- Bash is primary platform (macOS/Unix environment)
- Full parity may not be needed immediately
- Consider deprecating PowerShell if not used
