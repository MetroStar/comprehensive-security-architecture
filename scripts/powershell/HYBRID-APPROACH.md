# Hybrid PowerShell/Bash Approach

## Overview
The PowerShell orchestration scripts now use a **hybrid approach**:
- ✅ **PowerShell scripts** are used where available (converted tools)
- ⚠️ **Bash scripts** are used as fallback for tools not yet converted

## Current Script Usage

### ✅ Using PowerShell Scripts
These tools have been converted and the orchestration scripts call the `.ps1` versions:

1. **TruffleHog** - `run-trufflehog-scan.ps1`
   - Secret detection
   - Filesystem and container image scanning

2. **ClamAV** - `run-clamav-scan.ps1`
   - Antivirus/malware scanning

### ⚠️ Using Bash Scripts (Fallback)
These tools haven't been converted yet, so orchestration scripts call the `.sh` versions:

1. **Trivy** - `bash/run-trivy-scan.sh`
2. **Grype** - `bash/run-grype-scan.sh`
3. **Xeol** - `bash/run-xeol-scan.sh`
4. **Checkov** - `bash/run-checkov-scan.sh`
5. **Helm** - `bash/run-helm-build.sh`
6. **SonarQube** - `bash/run-sonar-analysis.sh`

## How It Works

### In `run-target-security-scan.ps1`
```powershell
# Uses PowerShell version
Invoke-SecurityTool "TruffleHog Secret Detection" "$ScriptDir\run-trufflehog-scan.ps1"
Invoke-SecurityTool "ClamAV Antivirus Scan" "$ScriptDir\run-clamav-scan.ps1"

# Falls back to bash version (not yet converted)
Invoke-SecurityTool "Grype Vulnerability Scanning" "$ScriptsRoot\bash\run-grype-scan.sh" "filesystem"
Invoke-SecurityTool "Trivy Security Analysis" "$ScriptsRoot\bash\run-trivy-scan.sh" "filesystem"
```

### In `run-complete-security-scan.ps1`
```powershell
# Layer 2: Secret Detection - Uses PowerShell
Invoke-SecurityTool "TruffleHog Filesystem" "$ScriptDir\run-trufflehog-scan.ps1"

# Layer 3: Malware Detection - Uses PowerShell
Invoke-SecurityTool "ClamAV Antivirus Scan" "$ScriptDir\run-clamav-scan.ps1"

# Layer 6: Vulnerability Detection - Uses bash (not converted)
Invoke-SecurityTool "Grype Filesystem" "$ScriptsRoot\bash\run-grype-scan.sh" "filesystem"
```

## Benefits of Hybrid Approach

### ✅ Advantages
1. **Immediate functionality** - Works right now without waiting for all conversions
2. **Progressive enhancement** - Can convert scripts one at a time
3. **Best of both worlds** - Native PowerShell where available, proven bash scripts as fallback
4. **Clear migration path** - Easy to see what's converted and what's not

### 📝 Notes in Code
Each bash fallback includes a comment:
```powershell
# Note: Grype not yet converted - use bash version
Invoke-SecurityTool "Grype Filesystem" "$ScriptsRoot\bash\run-grype-scan.sh" "filesystem"
```

## Requirements

### For Full Functionality
You need **both**:
1. ✅ **PowerShell 5.1+** (for .ps1 scripts)
2. ✅ **Git Bash or WSL** (for .sh scripts)

### Docker
All security tools require Docker Desktop for Windows.

## Migration Path

As more scripts are converted to PowerShell, update the orchestration scripts:

### Before (Bash)
```powershell
Invoke-SecurityTool "Trivy Security Analysis" "$ScriptsRoot\bash\run-trivy-scan.sh" "filesystem"
```

### After (PowerShell)
```powershell
Invoke-SecurityTool "Trivy Security Analysis" "$ScriptDir\run-trivy-scan.ps1"
```

## Conversion Priority

To make the orchestration scripts fully PowerShell, convert these in order:

### High Priority (Most Used)
1. ⏳ `run-trivy-scan.sh` → `run-trivy-scan.ps1`
2. ⏳ `run-grype-scan.sh` → `run-grype-scan.ps1`
3. ⏳ `run-xeol-scan.sh` → `run-xeol-scan.ps1`

### Medium Priority
4. ⏳ `run-checkov-scan.sh` → `run-checkov-scan.ps1`
5. ⏳ `run-helm-build.sh` → `run-helm-build.ps1`

### Lower Priority
6. ⏳ `run-sonar-analysis.sh` → `run-sonar-analysis.ps1`

## Current Status

| Tool | PowerShell | Bash | Used By Orchestration |
|------|------------|------|----------------------|
| TruffleHog | ✅ `.ps1` | ✅ `.sh` | **PowerShell** |
| ClamAV | ✅ `.ps1` | ✅ `.sh` | **PowerShell** |
| Trivy | ❌ | ✅ `.sh` | **Bash** |
| Grype | ❌ | ✅ `.sh` | **Bash** |
| Xeol | ❌ | ✅ `.sh` | **Bash** |
| Checkov | ❌ | ✅ `.sh` | **Bash** |
| Helm | ❌ | ✅ `.sh` | **Bash** |
| SonarQube | ❌ | ✅ `.sh` | **Bash** |

**PowerShell Usage**: 2/8 tools (25%)
**Bash Fallback**: 6/8 tools (75%)

## Testing

### Test PowerShell Scripts
```powershell
cd scripts\powershell

# Test individual PowerShell scripts
.\run-trufflehog-scan.ps1
.\run-clamav-scan.ps1

# Test orchestration (hybrid approach)
.\run-complete-security-scan.ps1 quick
```

### Verify Bash Fallback Works
```powershell
# Should call bash scripts for unconverted tools
.\run-complete-security-scan.ps1 full
# Watch for "Note: ... not yet converted" messages
```

## Future: Pure PowerShell

Once all tools are converted, the orchestration scripts will be **pure PowerShell**:

```powershell
# Future state - all PowerShell
Invoke-SecurityTool "TruffleHog" "$ScriptDir\run-trufflehog-scan.ps1"
Invoke-SecurityTool "ClamAV" "$ScriptDir\run-clamav-scan.ps1"
Invoke-SecurityTool "Trivy" "$ScriptDir\run-trivy-scan.ps1"      # ← Converted
Invoke-SecurityTool "Grype" "$ScriptDir\run-grype-scan.ps1"      # ← Converted
Invoke-SecurityTool "Xeol" "$ScriptDir\run-xeol-scan.ps1"        # ← Converted
Invoke-SecurityTool "Checkov" "$ScriptDir\run-checkov-scan.ps1"  # ← Converted
```

No Git Bash or WSL required! 🎉

---

**Status**: Hybrid approach active
**PowerShell Coverage**: 25% (2/8 tools)
**Next Step**: Convert Trivy, Grype, and Xeol scanners
