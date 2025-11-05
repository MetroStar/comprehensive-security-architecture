# PowerShell Script Conversion Guide

## Overview
This directory contains both shell scripts (.sh) and their PowerShell equivalents (.ps1) for Windows compatibility.

## Converted Scripts

### ✅ Completed Conversions

#### Utility Scripts
- `open-dashboard.ps1` - Opens the security dashboard in browser
- `force-refresh-dashboard.ps1` - Forces dashboard refresh with cache busting
- `test-desktop-default.ps1` - Tests desktop default behavior
- `demo-portable-scanner.ps1` - Demonstrates portable scanner usage

#### Scanner Scripts
- `run-clamav-scan.ps1` - ClamAV antivirus scanning

#### Management Scripts
- `create-stub-dependencies.ps1` - Creates stub Helm dependencies

## Key Differences Between Shell and PowerShell

### Path Separators
- **Shell**: `/` (forward slash)
- **PowerShell**: `\` (backslash) or `/` (both work)

### Environment Variables
- **Shell**: `$VAR` or `${VAR}`
- **PowerShell**: `$env:VAR`

### Command Execution
- **Shell**: `$(command)` or `` `command` ``
- **PowerShell**: `$(command)` or `& command`

### Colors
- **Shell**: ANSI escape codes (`\033[0;32m`)
- **PowerShell**: `-ForegroundColor` parameter

### File Tests
- **Shell**: `[ -f "$file" ]`
- **PowerShell**: `Test-Path $file`

### Docker Commands
Both use Docker CLI directly, but PowerShell uses backticks (`) for line continuation instead of backslashes (\).

## Running PowerShell Scripts

### Execution Policy
You may need to set the execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Running a Script
```powershell
.\script-name.ps1
```

### With Parameters
```powershell
.\script-name.ps1 -Parameter Value
```

## Common Conversion Patterns

### 1. Script Header
**Shell:**
```bash
#!/bin/bash
set -e
```

**PowerShell:**
```powershell
$ErrorActionPreference = "Stop"
```

### 2. Getting Script Directory
**Shell:**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

**PowerShell:**
```powershell
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
```

### 3. Creating Directories
**Shell:**
```bash
mkdir -p "$OUTPUT_DIR"
```

**PowerShell:**
```powershell
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
```

### 4. Docker Commands
**Shell:**
```bash
docker run --rm \
  -v "$PWD:/app" \
  image:tag \
  command
```

**PowerShell:**
```powershell
docker run --rm `
  -v "${PWD}:/app" `
  image:tag `
  command
```

### 5. Conditional Execution
**Shell:**
```bash
if [ $? -eq 0 ]; then
    echo "Success"
else
    echo "Failed"
fi
```

**PowerShell:**
```powershell
if ($LASTEXITCODE -eq 0) {
    Write-Host "Success"
} else {
    Write-Host "Failed"
}
```

### 6. Reading Files
**Shell:**
```bash
cat "$FILE" | grep "pattern"
```

**PowerShell:**
```powershell
Get-Content $File | Select-String "pattern"
```

### 7. Finding Files
**Shell:**
```bash
find . -name "*.txt"
```

**PowerShell:**
```powershell
Get-ChildItem -Path . -Filter "*.txt" -Recurse
```

## Pending Conversions

The following scripts still need PowerShell conversions:

### Scanner Scripts
- `run-trivy-scan.sh`
- `run-grype-scan.sh`
- `run-xeol-scan.sh`
- `run-trufflehog-scan.sh`
- `run-checkov-scan.sh`
- `run-helm-build.sh`
- `run-sonar-analysis.sh`

### Analysis Scripts
- `analyze-checkov-results.sh`
- `analyze-clamav-results.sh`
- `analyze-grype-results.sh`
- `analyze-helm-results.sh`
- `analyze-trivy-results.sh`
- `analyze-trufflehog-results.sh`
- `analyze-xeol-results.sh`

### Complex Scripts
- `consolidate-security-reports.sh`
- `portable-app-scanner.sh`
- `nodejs-security-scanner.sh`
- `real-nodejs-scanner.sh`
- `real-nodejs-scanner-fixed.sh`
- `run-complete-security-scan.sh`
- `run-target-security-scan.sh`

### Management Scripts
- `manage-dashboard-data.sh`
- `resolve-helm-dependencies.sh`
- `aws-ecr-helm-auth.sh`
- `aws-ecr-helm-auth-guide.sh`

## Notes

- All PowerShell scripts maintain the same functionality as their shell counterparts
- Docker commands work identically on both platforms
- File paths are automatically handled by PowerShell's path resolution
- Color output uses PowerShell's native color support instead of ANSI codes
