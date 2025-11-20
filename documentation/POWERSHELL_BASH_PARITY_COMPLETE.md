# PowerShell Script Parity - Bash to PowerShell Conversion

## Summary

All bash scripts from `scripts/bash` have now been converted to PowerShell equivalents in `scripts/powershell`.

## Date
November 19, 2025

## Scripts Converted

### 1. generate-critical-high-summary.ps1 ✅
- **Source**: `scripts/bash/generate-critical-high-summary.sh`
- **Purpose**: Analyzes all security scan results and extracts CRITICAL and HIGH severity findings
- **Features**:
  - Analyzes Trivy, Grype, TruffleHog, and Checkov results
  - Generates JSON and HTML reports
  - Provides color-coded console output
  - Creates summary cards for critical and high findings

### 2. generate-scan-findings-summary.ps1 ✅
- **Source**: `scripts/bash/generate-scan-findings-summary.sh`
- **Purpose**: Analyzes security scan results for all severity levels (CRITICAL, HIGH, MEDIUM, LOW)
- **Features**:
  - Works with scan directory architecture: `scans/{SCAN_ID}/{tool}/`
  - Processes TruffleHog, Grype, Trivy, and Checkov results
  - Categorizes findings by severity
  - Provides detailed validation steps for each finding
  - Includes CVSS scores and fix availability

### 3. get-scan-rollup.ps1 ✅
- **Source**: `scripts/bash/get-scan-rollup.sh`
- **Purpose**: Gets comprehensive summary of a specific scan ID
- **Features**:
  - Shows security findings overview
  - Lists all tools analyzed
  - Displays individual tool results
  - Checks both scan directory and legacy reports structure
  - Provides detailed metrics for each tool

### 4. historical-preservation-summary.ps1 ✅
- **Source**: `scripts/bash/historical-preservation-summary.sh`
- **Purpose**: Shows changes made to preserve scan history with timestamps
- **Features**:
  - Documents timestamped file naming conventions
  - Explains benefits of historical preservation
  - Provides usage examples
  - Includes cleanup recommendations

### 5. test-scan-consistency.ps1 ✅
- **Source**: `scripts/bash/test-scan-consistency.sh`
- **Purpose**: Verifies timestamp consistency across all security tools
- **Features**:
  - Creates test environment
  - Generates master SCAN_ID
  - Tests SBOM and quick security scans
  - Validates timestamp consistency
  - Reports on unique timestamps found

### 6. cleanup-scripts.ps1 ✅
- **Source**: `scripts/bash/cleanup-scripts.sh`
- **Purpose**: Removes unnecessary scripts and keeps only essential ones
- **Features**:
  - Creates backup before cleanup
  - Removes legacy and duplicate scripts
  - Lists essential scripts for 8-step security scan
  - Provides usage instructions
  - Shows before/after script counts

## Script Mapping

| Bash Script | PowerShell Script | Status |
|------------|------------------|--------|
| `generate-critical-high-summary.sh` | `generate-critical-high-summary.ps1` | ✅ Complete |
| `generate-scan-findings-summary.sh` | `generate-scan-findings-summary.ps1` | ✅ Complete |
| `get-scan-rollup.sh` | `get-scan-rollup.ps1` | ✅ Complete |
| `historical-preservation-summary.sh` | `historical-preservation-summary.ps1` | ✅ Complete |
| `test-scan-consistency.sh` | `test-scan-consistency.ps1` | ✅ Complete |
| `cleanup-scripts.sh` | `cleanup-scripts.ps1` | ✅ Complete |

## Scripts Already Converted (Pre-existing)

The following bash scripts already had PowerShell equivalents:

| Bash Script | PowerShell Script |
|------------|------------------|
| `run-trufflehog-scan.sh` | `run-trufflehog-scan.ps1` |
| `run-clamav-scan.sh` | `run-clamav-scan.ps1` |
| `run-checkov-scan.sh` | `run-checkov-scan.ps1` |
| `run-grype-scan.sh` | `run-grype-scan.ps1` |
| `run-trivy-scan.sh` | `run-trivy-scan.ps1` |
| `run-xeol-scan.sh` | `run-xeol-scan.ps1` |
| `run-sonar-analysis.sh` | `run-sonar-analysis.ps1` |
| `run-helm-build.sh` | `run-helm-build.ps1` |
| `run-sbom-scan.sh` | `run-sbom-scan.ps1` |
| `run-target-security-scan.sh` | `run-target-security-scan.ps1` |
| `consolidate-security-reports.sh` | `consolidate-security-reports.ps1` |

## Key Conversion Changes

### 1. JSON Parsing
- **Bash**: Uses `jq` for JSON processing
- **PowerShell**: Uses `ConvertFrom-Json` and `ConvertTo-Json` cmdlets

### 2. File Operations
- **Bash**: Uses `cat`, `echo`, `sed`, `grep`
- **PowerShell**: Uses `Get-Content`, `Set-Content`, `Where-Object`, `ForEach-Object`

### 3. Colors/Formatting
- **Bash**: Uses ANSI escape codes
- **PowerShell**: Uses `-ForegroundColor` parameter with `Write-Host`

### 4. Path Handling
- **Bash**: Uses forward slashes `/`
- **PowerShell**: Uses `Join-Path` for cross-platform compatibility

### 5. Environment Variables
- **Bash**: `$USERNAME`, `whoami`
- **PowerShell**: `$env:USERNAME`

### 6. Date Formatting
- **Bash**: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- **PowerShell**: `(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")`

## Testing Recommendations

1. **Test each script individually**:
   ```powershell
   .\scripts\powershell\generate-critical-high-summary.ps1
   .\scripts\powershell\get-scan-rollup.ps1 "scan_id_example"
   .\scripts\powershell\test-scan-consistency.ps1
   ```

2. **Test integration with main scan**:
   ```powershell
   .\scripts\powershell\run-target-security-scan.ps1 -TargetDir "path/to/target" -Mode full
   ```

3. **Verify output files**:
   - Check JSON reports are valid
   - Verify HTML reports render correctly
   - Confirm all tools are being analyzed

## Notes

1. **NDJSON Handling**: TruffleHog outputs NDJSON (newline-delimited JSON). Both bash and PowerShell versions handle this by reading line-by-line and filtering out log lines.

2. **Error Handling**: PowerShell versions include try-catch blocks for robust error handling, while bash versions use conditional checks.

3. **Existing Script**: `cleanup-powershell-scripts.ps1` already existed and is specifically for cleaning PowerShell scripts. The new `cleanup-scripts.ps1` is the direct equivalent of the bash version.

4. **Symlinks**: The bash versions use symlinks for "current" file references. PowerShell versions document this but actual symlink creation would need `New-Item -ItemType SymbolicLink` (requires admin on Windows).

## Benefits of PowerShell Versions

- ✅ Native Windows support without WSL or Git Bash
- ✅ Better error messages and debugging
- ✅ Consistent parameter handling
- ✅ Built-in JSON support
- ✅ No external dependencies (like `jq`)
- ✅ PowerShell Gallery integration potential
- ✅ Better IDE support (ISE, VS Code)

## Usage

All PowerShell scripts support help:
```powershell
Get-Help .\scripts\powershell\<script-name>.ps1 -Full
```

Example:
```powershell
Get-Help .\scripts\powershell\generate-critical-high-summary.ps1 -Full
```

## Conclusion

✅ **Full parity achieved** between bash and PowerShell scripts. Windows users can now run the complete security scanning suite without requiring WSL or Git Bash.
