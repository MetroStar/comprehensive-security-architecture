# PowerShell Scripts

PowerShell scripts for Windows (converted from bash).

## 📋 Available Scripts (11 total)

### Security Scanners (2)
- `run-clamav-scan.ps1` - ClamAV antivirus scanning
- `run-trufflehog-scan.ps1` - TruffleHog secret detection

### Orchestration Scripts (2)
- `run-complete-security-scan.ps1` - Run complete 8-layer security scan
- `run-target-security-scan.ps1` - Run security scan on external target directory

### Analysis Tools (1)
- `analyze-clamav-results.ps1` - Analyze ClamAV scan results

### Dashboard & Utilities (4)
- `open-dashboard.ps1` - Open security dashboard in browser
- `force-refresh-dashboard.ps1` - Force refresh dashboard with cache busting
- `test-desktop-default.ps1` - Test desktop default behavior
- `demo-portable-scanner.ps1` - Demonstrate portable scanner

### Management Tools (2)
- `create-stub-dependencies.ps1` - Create stub Helm dependencies
- `Convert-AllScripts.ps1` - Track conversion progress and generate templates

## 🚀 Usage

### Initial Setup
```powershell
# Set execution policy (one-time)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Navigate to directory
cd powershell
```

### Running Scripts
```powershell
# Run a script
.\script-name.ps1

# With parameters
.\script-name.ps1 -Parameter Value
```

### Common Workflows

**Quick Security Scan**
```powershell
.\run-complete-security-scan.ps1 quick
# or individual scans
.\run-clamav-scan.ps1
.\run-trufflehog-scan.ps1
.\analyze-clamav-results.ps1
.\open-dashboard.ps1
```

**Complete Security Scan**
```powershell
.\run-complete-security-scan.ps1 full
```

**Scan External Project**
```powershell
.\run-target-security-scan.ps1 "C:\path\to\project" full
```

**Check Conversion Status**
```powershell
.\Convert-AllScripts.ps1
```

**View Dashboard**
```powershell
.\open-dashboard.ps1
```

## 📚 Documentation

### Included Documentation Files
- `QUICK-START-WINDOWS.md` - Getting started guide for Windows users
- `README-PowerShell-Conversion.md` - Conversion guide with patterns and examples
- `CONVERSION-STATUS.md` - Detailed conversion progress tracking
- `CONVERSION-SUMMARY.md` - Project overview and summary

### Quick Links
- **New to PowerShell?** → Read `QUICK-START-WINDOWS.md`
- **Converting scripts?** → Read `README-PowerShell-Conversion.md`
- **Check progress?** → Run `.\Convert-AllScripts.ps1` or read `CONVERSION-STATUS.md`

## 📊 Conversion Status

**Progress**: 11/31 scripts converted (35.5%)

### ✅ Converted
- All utility scripts (4)
- 2 scanner scripts
- 2 orchestration scripts (complete & target scans)
- 1 analysis script
- 1 management script
- 1 helper tool

### ⏳ Pending
- 6 scanner scripts (Trivy, Grype, Xeol, Checkov, Helm, Sonar)
- 6 analysis scripts
- 3 orchestration scripts
- 4 management scripts
- 2 Node.js scanners

## 📦 Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Docker Desktop for Windows
- Optional: Helm, AWS CLI (for specific scripts)

## 📁 Output Locations

Results are saved to parent directory:
- `..\clamav-reports\`
- `..\trufflehog-reports\`
- `..\trivy-reports\`
- `..\grype-reports\`
- `..\xeol-reports\`
- `..\checkov-reports\`
- `..\reports\security-reports\`

## 🛠️ Troubleshooting

### "Cannot be loaded because running scripts is disabled"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Docker daemon is not running"
1. Start Docker Desktop
2. Wait for it to fully start
3. Verify: `docker ps`

### Script not yet converted
Use the bash version:
```bash
# In Git Bash or WSL
cd ../bash
./script-name.sh
```

## 💡 Tips

1. **Tab completion works**:
   ```powershell
   .\run-<TAB>  # Cycles through scripts
   ```

2. **Get help**:
   ```powershell
   Get-Help .\script-name.ps1
   ```

3. **View script content**:
   ```powershell
   Get-Content .\script-name.ps1
   ```

4. **Run in background**:
   ```powershell
   Start-Job -ScriptBlock { & ".\script-name.ps1" }
   Get-Job
   Receive-Job -Id 1
   ```

## 🔄 For Unconverted Scripts

If a script hasn't been converted yet, you have options:

1. **Use the bash version** (Git Bash or WSL):
   ```bash
   cd ../bash
   ./script-name.sh
   ```

2. **Convert it yourself**:
   ```powershell
   # Generate template
   .\Convert-AllScripts.ps1  # Answer 'Y'
   
   # Edit the generated .ps1 file
   # Use README-PowerShell-Conversion.md as guide
   ```

## 🔗 Related

- Bash versions available in `../bash/` directory
- See main `../README.md` for overall structure
- See `CONVERSION-STATUS.md` for detailed progress

## 🎯 Next Steps

1. Read `QUICK-START-WINDOWS.md` if you're new
2. Run `.\Convert-AllScripts.ps1` to see status
3. Try running `.\run-clamav-scan.ps1`
4. View results with `.\open-dashboard.ps1`
