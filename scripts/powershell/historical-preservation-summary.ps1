<#
.SYNOPSIS
    Historical Preservation Summary
    
.DESCRIPTION
    Shows the changes made to preserve scan history with timestamps
    
.NOTES
    PowerShell version of historical-preservation-summary.sh
#>

Write-Host "🔄 SCAN HISTORY PRESERVATION IMPLEMENTED"
Write-Host "========================================"
Write-Host ""
Write-Host "📊 Changes Applied to Security Scan Scripts:"
Write-Host ""

Write-Host "✅ TruffleHog (run-trufflehog-scan.ps1):"
Write-Host "   • Results: trufflehog-{type}-results-YYYY-MM-DD_HH-MM-SS.json"
Write-Host "   • Logs: trufflehog-scan-YYYY-MM-DD_HH-MM-SS.log"
Write-Host "   • Current symlinks: trufflehog-{type}-results.json → latest"
Write-Host ""

Write-Host "✅ Grype (run-grype-scan.ps1):"
Write-Host "   • Results: grype-{type}-results-YYYY-MM-DD_HH-MM-SS.json"
Write-Host "   • SBOMs: sbom-{type}-YYYY-MM-DD_HH-MM-SS.json"
Write-Host "   • Logs: grype-scan-YYYY-MM-DD_HH-MM-SS.log"
Write-Host "   • Current symlinks: grype-{type}-results.json → latest"
Write-Host ""

Write-Host "✅ Trivy (run-trivy-scan.ps1):"
Write-Host "   • Results: trivy-{type}-results-YYYY-MM-DD_HH-MM-SS.json"
Write-Host "   • Logs: trivy-scan-YYYY-MM-DD_HH-MM-SS.log"
Write-Host "   • Current symlinks: trivy-{type}-results.json → latest"
Write-Host ""

Write-Host "✅ Checkov (run-checkov-scan.ps1):"
Write-Host "   • Results: checkov-results-YYYY-MM-DD_HH-MM-SS.json"
Write-Host "   • Logs: checkov-scan-YYYY-MM-DD_HH-MM-SS.log"
Write-Host "   • Current symlinks: checkov-results.json → latest"
Write-Host ""

Write-Host "✅ ClamAV (run-clamav-scan.ps1):"
Write-Host "   • Results: clamav-detailed-YYYY-MM-DD_HH-MM-SS.log"
Write-Host "   • Logs: clamav-scan-YYYY-MM-DD_HH-MM-SS.log"
Write-Host "   • Current symlinks: clamav-detailed.log → latest"
Write-Host ""

Write-Host "✅ Xeol (run-xeol-scan.ps1):"
Write-Host "   • Results: xeol-{type}-results-YYYY-MM-DD_HH-MM-SS.json"
Write-Host "   • Logs: xeol-scan-YYYY-MM-DD_HH-MM-SS.log"
Write-Host "   • Current symlinks: xeol-{type}-results.json → latest"
Write-Host ""

Write-Host "✅ Helm Build (run-helm-build.ps1):"
Write-Host "   • Logs: helm-build-YYYY-MM-DD_HH-MM-SS.log"
Write-Host "   • Current symlinks: helm-build.log → latest"
Write-Host ""

Write-Host "🎯 BENEFITS OF HISTORICAL PRESERVATION:"
Write-Host "======================================="
Write-Host "• 📈 Trend Analysis: Compare security findings over time"
Write-Host "• 🔄 Rollback Capability: Access previous scan results"
Write-Host "• 📊 Audit Trail: Complete history of security scans"
Write-Host "• 🎯 Current Access: Symlinks always point to latest results"
Write-Host "• 🗂️  Organized Storage: Timestamped files prevent overwrites"
Write-Host ""

Write-Host "💡 USAGE EXAMPLES:"
Write-Host "=================="
Write-Host "# View latest results (unchanged)"
Write-Host "Get-Content reports\trivy-reports\trivy-filesystem-results.json"
Write-Host ""
Write-Host "# View historical results"
Write-Host "Get-ChildItem reports\trivy-reports\trivy-filesystem-results-*.json"
Write-Host ""
Write-Host "# Compare two scans"
Write-Host "Compare-Object ``"
Write-Host "  (Get-Content reports\grype-reports\grype-filesystem-results-2025-11-15_19-00-00.json) ``"
Write-Host "  (Get-Content reports\grype-reports\grype-filesystem-results-2025-11-15_20-00-00.json)"
Write-Host ""

Write-Host "🧹 CLEANUP RECOMMENDATIONS:"
Write-Host "==========================="
Write-Host "• Consider periodic cleanup of old files (keep last 10-30 scans)"
Write-Host "• Use log rotation for long-term storage management"
Write-Host "• Archive critical scan results for compliance purposes"
Write-Host ""

Write-Host "✅ All security scan scripts now preserve historical data!"
Write-Host "   Your analysis tools will continue to work with current symlinks."
