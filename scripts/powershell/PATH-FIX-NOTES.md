# Path Fix for Orchestration Scripts

## Issue
The PowerShell orchestration scripts (`run-target-security-scan.ps1` and `run-complete-security-scan.ps1`) were looking for bash scripts in the wrong location:

**Incorrect Path:**
```
C:\...\scripts\scripts\bash\run-xeol-scan.sh
                ^^^^^^^^ - doubled "scripts"
```

**Correct Path:**
```
C:\...\scripts\bash\run-xeol-scan.sh
```

## Root Cause
The scripts were calculating paths incorrectly:
- `$RepoRoot` was pointing to the `scripts/` directory
- Then adding `\scripts\bash\` resulted in `scripts\scripts\bash\`

## Solution
Updated path calculation in both scripts:

```powershell
# OLD (Incorrect)
$RepoRoot = Get-Location  # or Split-Path -Parent $ScriptDir

# NEW (Correct)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path  # powershell/
$ScriptsRoot = Split-Path -Parent $ScriptDir                  # scripts/
$RepoRoot = Split-Path -Parent $ScriptsRoot                   # project root/
```

## Path Hierarchy
```
comprehensive-security-architecture/     ← $RepoRoot
└── scripts/                             ← $ScriptsRoot
    ├── bash/                            ← Bash scripts location
    │   ├── run-xeol-scan.sh
    │   ├── run-trivy-scan.sh
    │   └── ... (31 scripts)
    └── powershell/                      ← $ScriptDir
        ├── run-target-security-scan.ps1
        ├── run-complete-security-scan.ps1
        └── ... (11 scripts)
```

## Files Fixed
1. ✅ `run-target-security-scan.ps1`
   - Fixed all bash script references
   - Updated consolidation script path

2. ✅ `run-complete-security-scan.ps1`
   - Fixed all bash script references
   - Updated consolidation script path

## Verification
All bash scripts now resolve to correct paths:
```powershell
$ScriptsRoot\bash\run-xeol-scan.sh
$ScriptsRoot\bash\run-trivy-scan.sh
$ScriptsRoot\bash\run-grype-scan.sh
$ScriptsRoot\bash\run-checkov-scan.sh
# etc.
```

## Testing
To verify paths are correct:
```powershell
cd scripts\powershell
.\run-target-security-scan.ps1 "C:\path\to\project" quick
# Should now find all bash scripts correctly
```

---

**Fixed**: November 4, 2024
**Status**: ✅ Resolved
