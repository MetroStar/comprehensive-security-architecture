# Quick Start Guide for Windows PowerShell Scripts

## 🚀 Getting Started

### Prerequisites
- Windows 10/11
- PowerShell 5.1 or later
- Docker Desktop for Windows (for security scanning tools)

### Initial Setup

1. **Set PowerShell Execution Policy** (one-time setup)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Navigate to Scripts Directory**
   ```powershell
   cd "c:\Users\ronni\OneDrive\Desktop\Projects\comprehensive-security-architecture\scripts"
   ```

3. **Verify Docker is Running**
   ```powershell
   docker --version
   docker ps
   ```

---

## 📊 Available PowerShell Scripts

### Dashboard & Utilities
```powershell
# Open the security dashboard
.\open-dashboard.ps1

# Force refresh the dashboard (clears cache)
.\force-refresh-dashboard.ps1

# Test desktop default behavior
.\test-desktop-default.ps1

# Demo the portable scanner
.\demo-portable-scanner.ps1
```

### Security Scanners
```powershell
# Run ClamAV antivirus scan
.\run-clamav-scan.ps1

# Run TruffleHog secret scanning
.\run-trufflehog-scan.ps1

# More scanners coming soon...
# .\run-trivy-scan.ps1
# .\run-grype-scan.ps1
# .\run-xeol-scan.ps1
# .\run-checkov-scan.ps1
```

### Analysis Tools
```powershell
# Analyze ClamAV scan results
.\analyze-clamav-results.ps1

# More analysis tools coming soon...
```

### Management Tools
```powershell
# Create stub Helm dependencies
.\create-stub-dependencies.ps1

# Check conversion status
.\Convert-AllScripts.ps1
```

---

## 🔍 Common Workflows

### Workflow 1: Quick Security Scan
```powershell
# 1. Run antivirus scan
.\run-clamav-scan.ps1

# 2. Run secret detection
.\run-trufflehog-scan.ps1

# 3. Analyze results
.\analyze-clamav-results.ps1

# 4. View dashboard
.\open-dashboard.ps1
```

### Workflow 2: Check Conversion Progress
```powershell
# Run the conversion tracker
.\Convert-AllScripts.ps1

# Review status document
Get-Content .\CONVERSION-STATUS.md

# Read conversion guide
Get-Content .\README-PowerShell-Conversion.md
```

### Workflow 3: Using Original Shell Scripts (if needed)
If a PowerShell version isn't available yet, you can use Git Bash or WSL:
```bash
# In Git Bash or WSL
./run-trivy-scan.sh
./run-grype-scan.sh
```

---

## 🛠️ Troubleshooting

### Issue: "Cannot be loaded because running scripts is disabled"
**Solution**: Set execution policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: "Docker daemon is not running"
**Solution**: Start Docker Desktop
1. Open Docker Desktop application
2. Wait for it to fully start
3. Verify: `docker ps`

### Issue: "Path not found" errors
**Solution**: Use full paths or navigate to scripts directory
```powershell
cd "c:\Users\ronni\OneDrive\Desktop\Projects\comprehensive-security-architecture\scripts"
```

### Issue: Script shows "under conversion" message
**Solution**: Use the original .sh script or wait for conversion
```powershell
# Check which scripts are converted
.\Convert-AllScripts.ps1
```

---

## 📁 Output Directories

All scan results are saved in their respective directories:
- `clamav-reports/` - ClamAV scan results
- `trufflehog-reports/` - TruffleHog secret scan results
- `trivy-reports/` - Trivy vulnerability scan results
- `grype-reports/` - Grype vulnerability scan results
- `xeol-reports/` - Xeol EOL detection results
- `checkov-reports/` - Checkov IaC scan results
- `reports/security-reports/` - Consolidated security reports

---

## 🎯 Next Steps

1. **Run your first scan**
   ```powershell
   .\run-clamav-scan.ps1
   ```

2. **Check the results**
   ```powershell
   .\analyze-clamav-results.ps1
   ```

3. **View the dashboard**
   ```powershell
   .\open-dashboard.ps1
   ```

4. **Track conversion progress**
   ```powershell
   .\Convert-AllScripts.ps1
   ```

---

## 📚 Documentation

- **Conversion Status**: `CONVERSION-STATUS.md`
- **Conversion Guide**: `README-PowerShell-Conversion.md`
- **This Guide**: `QUICK-START-WINDOWS.md`

---

## 💡 Tips

1. **Tab Completion**: PowerShell supports tab completion for script names
   ```powershell
   .\run-<TAB>  # Cycles through scripts starting with "run-"
   ```

2. **Get Help**: Many scripts show usage information
   ```powershell
   Get-Help .\script-name.ps1
   # or
   .\script-name.ps1 -?
   ```

3. **View Script Content**: Use `Get-Content` or `cat`
   ```powershell
   Get-Content .\run-clamav-scan.ps1
   ```

4. **Run in Background**: Use `Start-Job` for long-running scans
   ```powershell
   Start-Job -ScriptBlock { & ".\run-clamav-scan.ps1" }
   Get-Job
   Receive-Job -Id 1
   ```

---

## 🔗 Related Resources

- **Docker Desktop**: https://www.docker.com/products/docker-desktop
- **PowerShell Documentation**: https://docs.microsoft.com/powershell
- **Git for Windows** (includes Git Bash): https://git-scm.com/download/win
- **WSL** (Windows Subsystem for Linux): https://docs.microsoft.com/windows/wsl

---

**Happy Scanning! 🛡️**
