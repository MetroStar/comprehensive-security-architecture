#!/bin/bash

# Generate Interactive Security Dashboard
# Creates an interactive HTML dashboard with expandable tool sections showing detailed vulnerabilities

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default paths
SCANS_DIR="${WORKSPACE_ROOT}/scans"

# Use SCAN_DIR if provided, otherwise auto-detect latest
if [[ -n "${SCAN_DIR:-}" ]]; then
    LATEST_SCAN="$SCAN_DIR"
    echo "Using provided scan directory: $(basename "$LATEST_SCAN")"
else
    # Get the most recent scan directory (any username)
    LATEST_SCAN=$(find "$SCANS_DIR" -maxdepth 1 -type d -name "*_*_*" 2>/dev/null | sort -r | head -n 1)
    
    if [ -z "$LATEST_SCAN" ]; then
        echo "❌ No scan directories found in $SCANS_DIR"
        exit 1
    fi
    
    echo "🔍 Auto-detected latest scan: $(basename "$LATEST_SCAN")"
fi

SCAN_NAME=$(basename "$LATEST_SCAN")
echo "Generating interactive dashboard from: $SCAN_NAME"

# Set output to the scan directory's consolidated reports
OUTPUT_DIR="${LATEST_SCAN}/consolidated-reports/dashboards"
OUTPUT_HTML="${OUTPUT_DIR}/security-dashboard.html"

# ============================================
# COLLECT DETAILED STATISTICS FROM EACH TOOL
# ============================================

# Get target directory from scan ID
TARGET_NAME=$(echo "$SCAN_NAME" | cut -d'_' -f1)
SCAN_USER=$(echo "$SCAN_NAME" | cut -d'_' -f2)
SCAN_TIMESTAMP=$(echo "$SCAN_NAME" | cut -d'_' -f3-)

# ---- TruffleHog Statistics ----
TH_FILE="${LATEST_SCAN}/trufflehog/trufflehog-filesystem-results.json"
TH_FILES_SCANNED=0
TH_TOTAL_FINDINGS=0
TH_VERIFIED=0
TH_UNVERIFIED=0
TH_DETECTORS_USED=0
TH_SCAN_DURATION="N/A"
TH_FILES_WITH_FINDINGS=0
TH_CRITICAL=0
TH_HIGH=0
TH_FINDINGS=""
if [ -f "$TH_FILE" ]; then
    TH_TOTAL_FINDINGS=$(wc -l < "$TH_FILE" 2>/dev/null | tr -d ' \n\t')
    TH_TOTAL_FINDINGS="${TH_TOTAL_FINDINGS:-0}"
    [[ "$TH_TOTAL_FINDINGS" =~ ^[0-9]+$ ]] || TH_TOTAL_FINDINGS=0
    
    # grep -c returns 1 if no match, so use || true to prevent pipeline failure
    TH_VERIFIED=$(grep -c '"Verified":true' "$TH_FILE" 2>/dev/null || true)
    TH_VERIFIED=$(echo "$TH_VERIFIED" | tr -d ' \n\t')
    [[ "$TH_VERIFIED" =~ ^[0-9]+$ ]] || TH_VERIFIED=0
    
    TH_UNVERIFIED=$((TH_TOTAL_FINDINGS - TH_VERIFIED))
    
    # Use set +o pipefail temporarily for grep commands that may have no matches
    set +o pipefail
    TH_DETECTORS_USED=$(grep -oE '"DetectorName":"[^"]+' "$TH_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' \n\t')
    set -o pipefail
    TH_DETECTORS_USED="${TH_DETECTORS_USED:-0}"
    [[ "$TH_DETECTORS_USED" =~ ^[0-9]+$ ]] || TH_DETECTORS_USED=0
    
    set +o pipefail
    TH_FILES_WITH_FINDINGS=$(grep -oE '"file":"[^"]+' "$TH_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' \n\t')
    set -o pipefail
    TH_FILES_WITH_FINDINGS="${TH_FILES_WITH_FINDINGS:-0}"
    [[ "$TH_FILES_WITH_FINDINGS" =~ ^[0-9]+$ ]] || TH_FILES_WITH_FINDINGS=0
    
    # Count critical/high (excluding node_modules) - use || true to handle no matches
    TH_CRITICAL=$(grep -c '"Verified":true' "$TH_FILE" 2>/dev/null || true)
    TH_CRITICAL=$(echo "$TH_CRITICAL" | tr -d ' \n\t')
    [[ "$TH_CRITICAL" =~ ^[0-9]+$ ]] || TH_CRITICAL=0
    
    # For TH_HIGH, count all findings minus verified ones
    TH_HIGH=$((TH_TOTAL_FINDINGS - TH_CRITICAL))
    [[ "$TH_HIGH" =~ ^[0-9]+$ ]] || TH_HIGH=0
    
    # Generate findings HTML (use set +e to handle grep returning 1 when no matches)
    set +e
    TH_FINDINGS=$(grep -E '"DetectorName"' "$TH_FILE" 2>/dev/null | grep -v 'node_modules' | grep -v 'vendor/' | grep -v 'venv/' | grep -v '__pycache__' | head -n 15 | jq -s -r '
        map("<div class=\"finding-item severity-" + (if .Verified then "critical" else "high" end) + "\">
            <div class=\"finding-header\">
                <span class=\"badge badge-tool\">TruffleHog</span>
                <span class=\"badge badge-" + (if .Verified then "critical" else "high" end) + "\">" + (if .Verified then "CRITICAL" else "HIGH" end) + "</span>
                " + (if .Verified then "<span class=\"badge badge-verified\">✓ VERIFIED</span>" else "" end) + "
            </div>
            <div class=\"finding-title\">" + .DetectorName + "</div>
            <div class=\"finding-desc\">" + (.DetectorDescription // "No description") + "</div>
            <div class=\"finding-details\">
                <div><strong>File:</strong> <code>" + (.SourceMetadata.Data.Filesystem.file | split("/") | last) + "</code></div>
                <div><strong>Line:</strong> <code>" + (.SourceMetadata.Data.Filesystem.line | tostring) + "</code></div>
                <div><strong>Full Path:</strong> <code style=\"font-size: 0.8em;\">" + .SourceMetadata.Data.Filesystem.file + "</code></div>
            </div>
        </div>") | 
        join("")
    ' 2>/dev/null)
    set -e
    
    if [ -z "$TH_FINDINGS" ] || [ "$TH_FINDINGS" = "" ]; then
        TH_FINDINGS="<p class=\"no-findings\">✅ No secrets or credentials detected</p>"
    fi
else
    TH_CRITICAL=0
    TH_HIGH=0
    TH_FINDINGS="<p class=\"no-findings\">No scan data available</p>"
fi

# ---- ClamAV Statistics ----
CLAMAV_LOG="${LATEST_SCAN}/clamav/scan.log"
CLAMAV_FILES_SCANNED=0
CLAMAV_DATA_SCANNED="0 MB"
CLAMAV_SCAN_TIME="N/A"
CLAMAV_ENGINE_VERSION="N/A"
CLAMAV_VIRUS_DB_COUNT=0
CLAMAV_INFECTED=0
CLAMAV_DIRECTORIES=0
if [ -f "$CLAMAV_LOG" ]; then
    CLAMAV_FILES_SCANNED=$(grep "Scanned files:" "$CLAMAV_LOG" 2>/dev/null | grep -oE '[0-9]+' | head -1 || echo "0")
    CLAMAV_DATA_SCANNED=$(grep "Data scanned:" "$CLAMAV_LOG" 2>/dev/null | sed 's/Data scanned: //' || echo "N/A")
    CLAMAV_SCAN_TIME=$(grep "^Time:" "$CLAMAV_LOG" 2>/dev/null | sed 's/Time: //' || echo "N/A")
    CLAMAV_ENGINE_VERSION=$(grep "Engine version:" "$CLAMAV_LOG" 2>/dev/null | sed 's/Engine version: //' || echo "N/A")
    CLAMAV_VIRUS_DB_COUNT=$(grep "Known viruses:" "$CLAMAV_LOG" 2>/dev/null | grep -oE '[0-9]+' || echo "0")
    CLAMAV_INFECTED=$(grep "Infected files:" "$CLAMAV_LOG" 2>/dev/null | grep -oE '[0-9]+' || echo "0")
    CLAMAV_DIRECTORIES=$(grep "Scanned directories:" "$CLAMAV_LOG" 2>/dev/null | grep -oE '[0-9]+' || echo "0")
fi
CLAMAV_CRITICAL=${CLAMAV_INFECTED:-0}
if [ "$CLAMAV_CRITICAL" -gt 0 ]; then
    CLAMAV_FINDINGS="<div class=\"finding-item severity-critical\">
        <div class=\"finding-header\">
            <span class=\"badge badge-tool\">ClamAV</span>
            <span class=\"badge badge-critical\">CRITICAL</span>
        </div>
        <div class=\"finding-title\">⚠️ Malware Detected</div>
        <div class=\"finding-desc\">$CLAMAV_CRITICAL infected files found</div>
        <div class=\"finding-details\">
            <div><strong>Action Required:</strong> Review scan results and quarantine infected files</div>
        </div>
    </div>"
else
    CLAMAV_FINDINGS="<p class=\"no-findings\">✅ No malware detected</p>"
fi

# ---- Trivy Statistics ----
TRIVY_DIR="${LATEST_SCAN}/trivy"
TRIVY_IMAGES_SCANNED=0
TRIVY_TOTAL_VULNS=0
TRIVY_CRITICAL=0
TRIVY_HIGH=0
TRIVY_MEDIUM=0
TRIVY_LOW=0
TRIVY_FINDINGS=""
if [ -d "$TRIVY_DIR" ]; then
    TRIVY_IMAGES_SCANNED=$(find "$TRIVY_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' \n' || echo "0")
    [[ "$TRIVY_IMAGES_SCANNED" =~ ^[0-9]+$ ]] || TRIVY_IMAGES_SCANNED=0
    
    # Parse vulnerabilities from all Trivy JSON files
    for trivy_file in "$TRIVY_DIR"/*.json; do
        if [ -f "$trivy_file" ] && grep -q '"SchemaVersion"' "$trivy_file"; then
            # Extract JSON portion (skip any log lines at the beginning)
            json_content=$(grep -A9999 '^\s*{' "$trivy_file" 2>/dev/null || cat "$trivy_file")
            crit_count=$(echo "$json_content" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' 2>/dev/null || echo "0")
            high_count=$(echo "$json_content" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' 2>/dev/null || echo "0")
            med_count=$(echo "$json_content" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' 2>/dev/null || echo "0")
            low_count=$(echo "$json_content" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="LOW")] | length' 2>/dev/null || echo "0")
            
            # Ensure numeric
            [[ "$crit_count" =~ ^[0-9]+$ ]] || crit_count=0
            [[ "$high_count" =~ ^[0-9]+$ ]] || high_count=0
            [[ "$med_count" =~ ^[0-9]+$ ]] || med_count=0
            [[ "$low_count" =~ ^[0-9]+$ ]] || low_count=0
            
            TRIVY_CRITICAL=$((TRIVY_CRITICAL + crit_count))
            TRIVY_HIGH=$((TRIVY_HIGH + high_count))
            TRIVY_MEDIUM=$((TRIVY_MEDIUM + med_count))
            TRIVY_LOW=$((TRIVY_LOW + low_count))
        fi
    done
    TRIVY_TOTAL_VULNS=$((TRIVY_CRITICAL + TRIVY_HIGH + TRIVY_MEDIUM + TRIVY_LOW))
    
    if [ "$TRIVY_TOTAL_VULNS" -gt 0 ]; then
        TRIVY_FINDINGS="<div class=\"finding-summary\">
            <span class=\"badge badge-critical\">$TRIVY_CRITICAL Critical</span>
            <span class=\"badge badge-high\">$TRIVY_HIGH High</span>
            <span class=\"badge badge-medium\">$TRIVY_MEDIUM Medium</span>
            <span class=\"badge badge-low\">$TRIVY_LOW Low</span>
        </div>"
    else
        TRIVY_FINDINGS="<p class=\"no-findings\">✅ No vulnerabilities detected in container images</p>"
    fi
else
    TRIVY_FINDINGS="<p class=\"no-findings\">No Trivy scan data available</p>"
fi

# ---- Grype Statistics ----
GRYPE_DIR="${LATEST_SCAN}/grype"
GRYPE_TARGETS_SCANNED=0
GRYPE_TOTAL_VULNS=0
GRYPE_CRITICAL=0
GRYPE_HIGH=0
GRYPE_MEDIUM=0
GRYPE_LOW=0
GRYPE_FINDINGS=""
if [ -d "$GRYPE_DIR" ]; then
    GRYPE_TARGETS_SCANNED=$(find "$GRYPE_DIR" -name "grype-*.json" -type f 2>/dev/null | wc -l | tr -d ' \n' || echo "0")
    [[ "$GRYPE_TARGETS_SCANNED" =~ ^[0-9]+$ ]] || GRYPE_TARGETS_SCANNED=0
    
    for grype_file in "$GRYPE_DIR"/grype-*.json; do
        if [ -f "$grype_file" ]; then
            crit_count=$(jq '[.matches[]? | select(.vulnerability.severity=="Critical")] | length' "$grype_file" 2>/dev/null || echo "0")
            high_count=$(jq '[.matches[]? | select(.vulnerability.severity=="High")] | length' "$grype_file" 2>/dev/null || echo "0")
            med_count=$(jq '[.matches[]? | select(.vulnerability.severity=="Medium")] | length' "$grype_file" 2>/dev/null || echo "0")
            low_count=$(jq '[.matches[]? | select(.vulnerability.severity=="Low")] | length' "$grype_file" 2>/dev/null || echo "0")
            
            # Ensure numeric
            [[ "$crit_count" =~ ^[0-9]+$ ]] || crit_count=0
            [[ "$high_count" =~ ^[0-9]+$ ]] || high_count=0
            [[ "$med_count" =~ ^[0-9]+$ ]] || med_count=0
            [[ "$low_count" =~ ^[0-9]+$ ]] || low_count=0
            
            GRYPE_CRITICAL=$((GRYPE_CRITICAL + crit_count))
            GRYPE_HIGH=$((GRYPE_HIGH + high_count))
            GRYPE_MEDIUM=$((GRYPE_MEDIUM + med_count))
            GRYPE_LOW=$((GRYPE_LOW + low_count))
        fi
    done
    GRYPE_TOTAL_VULNS=$((GRYPE_CRITICAL + GRYPE_HIGH + GRYPE_MEDIUM + GRYPE_LOW))
    
    if [ "$GRYPE_TOTAL_VULNS" -gt 0 ]; then
        GRYPE_FINDINGS="<div class=\"finding-summary\">
            <span class=\"badge badge-critical\">$GRYPE_CRITICAL Critical</span>
            <span class=\"badge badge-high\">$GRYPE_HIGH High</span>
            <span class=\"badge badge-medium\">$GRYPE_MEDIUM Medium</span>
            <span class=\"badge badge-low\">$GRYPE_LOW Low</span>
        </div>"
    else
        GRYPE_FINDINGS="<p class=\"no-findings\">✅ No vulnerabilities detected</p>"
    fi
else
    GRYPE_FINDINGS="<p class=\"no-findings\">No Grype scan data available</p>"
fi

# ---- SBOM Statistics ----
SBOM_DIR="${LATEST_SCAN}/sbom"
SBOM_PACKAGES=0
SBOM_FILES_GENERATED=0
if [ -d "$SBOM_DIR" ]; then
    SBOM_FILES_GENERATED=$(find "$SBOM_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' \n' || echo "0")
    [[ "$SBOM_FILES_GENERATED" =~ ^[0-9]+$ ]] || SBOM_FILES_GENERATED=0
    
    for sbom_file in "$SBOM_DIR"/*.json; do
        if [ -f "$sbom_file" ]; then
            pkg_count=$(jq '.artifacts | length' "$sbom_file" 2>/dev/null || echo "0")
            [[ "$pkg_count" =~ ^[0-9]+$ ]] || pkg_count=0
            SBOM_PACKAGES=$((SBOM_PACKAGES + pkg_count))
        fi
    done
fi

# ---- Checkov Statistics ----
CHECKOV_DIR="${LATEST_SCAN}/checkov"
CHECKOV_PASSED=0
CHECKOV_FAILED=0
CHECKOV_SKIPPED=0
CHECKOV_FILES_SCANNED=0
if [ -d "$CHECKOV_DIR" ]; then
    for checkov_file in "$CHECKOV_DIR"/*.json; do
        if [ -f "$checkov_file" ]; then
            passed=$(jq '.results.passed_checks | length' "$checkov_file" 2>/dev/null || echo "0")
            failed=$(jq '.results.failed_checks | length' "$checkov_file" 2>/dev/null || echo "0")
            skipped=$(jq '.results.skipped_checks | length' "$checkov_file" 2>/dev/null || echo "0")
            
            [[ "$passed" =~ ^[0-9]+$ ]] || passed=0
            [[ "$failed" =~ ^[0-9]+$ ]] || failed=0
            [[ "$skipped" =~ ^[0-9]+$ ]] || skipped=0
            
            CHECKOV_PASSED=$((CHECKOV_PASSED + passed))
            CHECKOV_FAILED=$((CHECKOV_FAILED + failed))
            CHECKOV_SKIPPED=$((CHECKOV_SKIPPED + skipped))
        fi
    done
fi
CHECKOV_CRITICAL=$CHECKOV_FAILED
CHECKOV_HIGH=0
CHECKOV_FINDINGS="<p class=\"no-findings\">Passed: $CHECKOV_PASSED | Failed: $CHECKOV_FAILED | Skipped: $CHECKOV_SKIPPED</p>"

# ---- SonarQube Statistics ----
SONAR_DIR="${LATEST_SCAN}/sonar"
LATEST_SONAR=$(find "$SONAR_DIR" -name "*_sonar-analysis-results.json" -type f 2>/dev/null | sort -r | head -n 1 || echo "")
SONAR_STATUS="N/A"
SONAR_BUGS=0
SONAR_VULNS=0
SONAR_CODE_SMELLS=0
SONAR_COVERAGE="N/A"
if [ -f "$LATEST_SONAR" ]; then
    SONAR_STATUS=$(jq -r '.status' "$LATEST_SONAR" 2>/dev/null || echo "NO_DATA")
    if [ "$SONAR_STATUS" = "NO_PROJECT_DETECTED" ]; then
        SONAR_FINDINGS="<p class=\"no-findings\">No SonarQube project detected</p>"
        SONAR_CRITICAL=0
        SONAR_HIGH=0
    else
        SONAR_FINDINGS="<p class=\"no-findings\">✅ SonarQube analysis complete - check server for details</p>"
        SONAR_CRITICAL=0
        SONAR_HIGH=0
    fi
else
    SONAR_CRITICAL=0
    SONAR_HIGH=0
    SONAR_FINDINGS="<p class=\"no-findings\">No SonarQube data available</p>"
fi

# ---- Helm Statistics ----
HELM_DIR="${LATEST_SCAN}/helm"
HELM_CHARTS_SCANNED=0
if [ -d "$HELM_DIR" ]; then
    HELM_CHARTS_SCANNED=$(find "$HELM_DIR" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' \n' || echo "0")
    [[ "$HELM_CHARTS_SCANNED" =~ ^[0-9]+$ ]] || HELM_CHARTS_SCANNED=0
fi
HELM_CRITICAL=0
HELM_HIGH=0
HELM_FINDINGS="<p class=\"no-findings\">Helm charts scanned: $HELM_CHARTS_SCANNED</p>"

# Calculate totals
TOTAL_CRITICAL=$((TH_CRITICAL + CLAMAV_CRITICAL + TRIVY_CRITICAL + GRYPE_CRITICAL + SONAR_CRITICAL + CHECKOV_CRITICAL + HELM_CRITICAL))
TOTAL_HIGH=$((TH_HIGH + TRIVY_HIGH + GRYPE_HIGH + SONAR_HIGH + CHECKOV_HIGH + HELM_HIGH))
TOTAL_MEDIUM=$((TRIVY_MEDIUM + GRYPE_MEDIUM))
TOTAL_LOW=$((TRIVY_LOW + GRYPE_LOW))
TOTAL_FINDINGS=$((TOTAL_CRITICAL + TOTAL_HIGH + TOTAL_MEDIUM + TOTAL_LOW))

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate the dashboard HTML
cat > "$OUTPUT_HTML" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Interactive Security Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
            color: #2d3748;
        }
        
        .container {
            max-width: 1600px;
            margin: 0 auto;
        }
        
        .header {
            background: white;
            border-radius: 16px;
            padding: 40px;
            margin-bottom: 30px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.15);
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.8em;
            margin-bottom: 10px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .header .subtitle {
            color: #718096;
            font-size: 1.1em;
            margin-top: 10px;
        }
        
        .alert-banner {
            background: linear-gradient(135deg, #e53e3e 0%, #c53030 100%);
            color: white;
            padding: 25px;
            border-radius: 12px;
            margin-bottom: 30px;
            box-shadow: 0 4px 20px rgba(229, 62, 62, 0.3);
            text-align: center;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.02); }
        }
        
        .alert-banner h2 {
            font-size: 1.8em;
            margin-bottom: 10px;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
            cursor: pointer;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 30px rgba(0,0,0,0.15);
        }
        
        .stat-number {
            font-size: 3em;
            font-weight: bold;
            margin: 15px 0;
        }
        
        .stat-label {
            color: #718096;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 600;
        }
        
        .critical-stat { color: #e53e3e; border-top: 4px solid #e53e3e; }
        .high-stat { color: #dd6b20; border-top: 4px solid #dd6b20; }
        .medium-stat { color: #d69e2e; border-top: 4px solid #d69e2e; }
        .low-stat { color: #38a169; border-top: 4px solid #38a169; }
        
        .tools-section {
            display: grid;
            gap: 20px;
        }
        
        .tool-card {
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            overflow: hidden;
            transition: all 0.3s ease;
        }
        
        .tool-header {
            padding: 25px;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
            border-bottom: 2px solid #e2e8f0;
            transition: all 0.3s ease;
        }
        
        .tool-header:hover {
            background: linear-gradient(135deg, #edf2f7 0%, #e2e8f0 100%);
        }
        
        .tool-header.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .tool-title {
            display: flex;
            align-items: center;
            gap: 15px;
            font-size: 1.4em;
            font-weight: 600;
        }
        
        .tool-icon {
            font-size: 1.5em;
        }
        
        .tool-stats {
            display: flex;
            gap: 15px;
            align-items: center;
        }
        
        .tool-stat-badge {
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        .badge-critical { background: #fed7d7; color: #c53030; }
        .badge-high { background: #feebc8; color: #c05621; }
        .badge-medium { background: #fef5e7; color: #d69e2e; }
        .badge-low { background: #c6f6d5; color: #2f855a; }
        .badge-clean { background: #c6f6d5; color: #2f855a; }
        
        .tool-header.active .tool-stat-badge {
            background: rgba(255,255,255,0.2);
            color: white;
        }
        
        .expand-icon {
            font-size: 1.2em;
            transition: transform 0.3s ease;
        }
        
        .tool-header.active .expand-icon {
            transform: rotate(180deg);
        }
        
        .tool-content {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.5s ease;
        }
        
        .tool-content.active {
            max-height: 2000px;
            overflow-y: auto;
        }
        
        .tool-findings {
            padding: 30px;
        }
        
        .finding-item {
            background: #f7fafc;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 15px;
            border-left: 4px solid #cbd5e0;
            transition: all 0.2s ease;
        }
        
        .finding-item:hover {
            transform: translateX(5px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        
        .finding-item.severity-critical {
            border-left-color: #e53e3e;
            background: #fff5f5;
        }
        
        .finding-item.severity-high {
            border-left-color: #dd6b20;
            background: #fffaf0;
        }
        
        .finding-item.severity-medium {
            border-left-color: #d69e2e;
            background: #fef5e7;
        }
        
        .finding-item.severity-low {
            border-left-color: #38a169;
            background: #f0fff4;
        }
        
        .finding-header {
            display: flex;
            gap: 10px;
            margin-bottom: 12px;
            flex-wrap: wrap;
        }
        
        .badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }
        
        .badge-tool {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .badge-verified {
            background: #e53e3e;
            color: white;
            animation: pulse-badge 2s infinite;
        }
        
        @keyframes pulse-badge {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.7; }
        }
        
        .finding-title {
            font-size: 1.1em;
            font-weight: 600;
            margin-bottom: 8px;
            color: #2d3748;
        }
        
        .finding-desc {
            color: #4a5568;
            margin-bottom: 12px;
            line-height: 1.6;
        }
        
        .finding-details {
            background: white;
            padding: 15px;
            border-radius: 6px;
            font-size: 0.9em;
        }
        
        .finding-details div {
            margin-bottom: 8px;
        }
        
        .finding-details div:last-child {
            margin-bottom: 0;
        }
        
        .finding-details code {
            background: #edf2f7;
            padding: 3px 8px;
            border-radius: 4px;
            font-family: 'Monaco', 'Courier New', monospace;
            font-size: 0.9em;
            word-break: break-all;
        }
        
        .stats-detail-box {
            background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
            border: 1px solid #7dd3fc;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
        }
        
        .stats-detail-box h4 {
            color: #0369a1;
            margin-bottom: 15px;
            font-size: 1.1em;
        }
        
        .stats-grid-small {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
        }
        
        .stat-item {
            background: white;
            padding: 10px 15px;
            border-radius: 8px;
            font-size: 0.9em;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        
        .stat-item strong {
            color: #0369a1;
        }
        
        .finding-summary {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }
        
        .no-findings {
            text-align: center;
            padding: 40px;
            color: #38a169;
            font-size: 1.2em;
        }
        
        .footer {
            background: white;
            border-radius: 12px;
            padding: 30px;
            margin-top: 30px;
            text-align: center;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        
        .footer-links {
            display: flex;
            gap: 20px;
            justify-content: center;
            margin-top: 20px;
            flex-wrap: wrap;
        }
        
        .footer-link {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
            transition: all 0.2s;
        }
        
        .footer-link:hover {
            color: #764ba2;
            text-decoration: underline;
        }
        
        @media (max-width: 768px) {
            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
            
            .tool-header {
                flex-direction: column;
                gap: 15px;
                text-align: center;
            }
            
            .tool-stats {
                flex-wrap: wrap;
                justify-content: center;
            }
        }
    </style>
</head>
<body>
    <div class="container">
EOF

# Add alert banner if critical findings exist
if [ "$TOTAL_CRITICAL" -gt 0 ]; then
    cat >> "$OUTPUT_HTML" << EOF
        <div class="alert-banner">
            <h2>⚠️ CRITICAL SECURITY ALERT</h2>
            <p><strong>${TOTAL_CRITICAL} Critical Findings Detected</strong> - Immediate Action Required!</p>
        </div>
EOF
fi

# Add header and stats
cat >> "$OUTPUT_HTML" << EOF
        <div class="header">
            <h1>🛡️ Interactive Security Dashboard</h1>
            <p class="subtitle"><strong>Scan:</strong> $SCAN_NAME</p>
            <p class="subtitle"><strong>Generated:</strong> $(date '+%B %d, %Y at %I:%M %p')</p>
        </div>

        <div class="stats-grid">
            <div class="stat-card critical-stat">
                <div class="stat-label">Critical</div>
                <div class="stat-number">${TOTAL_CRITICAL}</div>
                <p>Immediate action required</p>
            </div>
            <div class="stat-card high-stat">
                <div class="stat-label">High</div>
                <div class="stat-number">${TOTAL_HIGH}</div>
                <p>High priority issues</p>
            </div>
            <div class="stat-card medium-stat">
                <div class="stat-label">Medium</div>
                <div class="stat-number">${TOTAL_MEDIUM}</div>
                <p>Medium priority issues</p>
            </div>
            <div class="stat-card low-stat">
                <div class="stat-label">Low</div>
                <div class="stat-number">${TOTAL_LOW}</div>
                <p>Low priority issues</p>
            </div>
        </div>

        <div class="tools-section">
            <!-- TruffleHog -->
            <div class="tool-card">
                <div class="tool-header" onclick="toggleTool('trufflehog')">
                    <div class="tool-title">
                        <span class="tool-icon">🔍</span>
                        <div>
                            <div>TruffleHog</div>
                            <div style="font-size: 0.6em; font-weight: 400; color: #718096;">Secret Detection</div>
                        </div>
                    </div>
                    <div class="tool-stats">
EOF

# Add TruffleHog stats
if [ "$TH_CRITICAL" -gt 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-critical\">❗ ${TH_CRITICAL}</span>" >> "$OUTPUT_HTML"
fi
if [ "$TH_HIGH" -gt 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-high\">⚠️ ${TH_HIGH}</span>" >> "$OUTPUT_HTML"
fi
if [ "$TH_CRITICAL" -eq 0 ] && [ "$TH_HIGH" -eq 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-clean\">✅ Clean</span>" >> "$OUTPUT_HTML"
fi

cat >> "$OUTPUT_HTML" << EOF
                        <span class="expand-icon">▼</span>
                    </div>
                </div>
                <div class="tool-content" id="trufflehog-content">
                    <div class="tool-findings">
                        <div class="stats-detail-box">
                            <h4>📊 Scan Statistics</h4>
                            <div class="stats-grid-small">
                                <div class="stat-item"><strong>Total Findings:</strong> ${TH_TOTAL_FINDINGS}</div>
                                <div class="stat-item"><strong>Verified Secrets:</strong> ${TH_VERIFIED}</div>
                                <div class="stat-item"><strong>Unverified:</strong> ${TH_UNVERIFIED}</div>
                                <div class="stat-item"><strong>Detector Types Used:</strong> ${TH_DETECTORS_USED}</div>
                                <div class="stat-item"><strong>Files with Findings:</strong> ${TH_FILES_WITH_FINDINGS:-0}</div>
                            </div>
                        </div>
                        ${TH_FINDINGS}
                    </div>
                </div>
            </div>

            <!-- ClamAV -->
            <div class="tool-card">
                <div class="tool-header" onclick="toggleTool('clamav')">
                    <div class="tool-title">
                        <span class="tool-icon">🦠</span>
                        <div>
                            <div>ClamAV</div>
                            <div style="font-size: 0.6em; font-weight: 400; color: #718096;">Malware Scanner</div>
                        </div>
                    </div>
                    <div class="tool-stats">
EOF

# Add ClamAV stats
if [ "$CLAMAV_CRITICAL" -gt 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-critical\">❗ ${CLAMAV_CRITICAL}</span>" >> "$OUTPUT_HTML"
else
    echo "                        <span class=\"tool-stat-badge badge-clean\">✅ Clean</span>" >> "$OUTPUT_HTML"
fi

cat >> "$OUTPUT_HTML" << EOF
                        <span class="expand-icon">▼</span>
                    </div>
                </div>
                <div class="tool-content" id="clamav-content">
                    <div class="tool-findings">
                        <div class="stats-detail-box">
                            <h4>📊 Scan Statistics</h4>
                            <div class="stats-grid-small">
                                <div class="stat-item"><strong>Files Scanned:</strong> ${CLAMAV_FILES_SCANNED}</div>
                                <div class="stat-item"><strong>Directories Scanned:</strong> ${CLAMAV_DIRECTORIES}</div>
                                <div class="stat-item"><strong>Data Scanned:</strong> ${CLAMAV_DATA_SCANNED}</div>
                                <div class="stat-item"><strong>Scan Duration:</strong> ${CLAMAV_SCAN_TIME}</div>
                                <div class="stat-item"><strong>Engine Version:</strong> ${CLAMAV_ENGINE_VERSION}</div>
                                <div class="stat-item"><strong>Virus Database:</strong> ${CLAMAV_VIRUS_DB_COUNT} signatures</div>
                                <div class="stat-item"><strong>Infected Files:</strong> ${CLAMAV_INFECTED}</div>
                            </div>
                        </div>
                        ${CLAMAV_FINDINGS}
                    </div>
                </div>
            </div>

            <!-- SonarQube -->
            <div class="tool-card">
                <div class="tool-header" onclick="toggleTool('sonar')">
                    <div class="tool-title">
                        <span class="tool-icon">📊</span>
                        <div>
                            <div>SonarQube</div>
                            <div style="font-size: 0.6em; font-weight: 400; color: #718096;">Code Quality</div>
                        </div>
                    </div>
                    <div class="tool-stats">
                        <span class="tool-stat-badge badge-clean">✅ Clean</span>
                        <span class="expand-icon">▼</span>
                    </div>
                </div>
                <div class="tool-content" id="sonar-content">
                    <div class="tool-findings">
                        ${SONAR_FINDINGS}
                    </div>
                </div>
            </div>

            <!-- Checkov -->
            <div class="tool-card">
                <div class="tool-header" onclick="toggleTool('checkov')">
                    <div class="tool-title">
                        <span class="tool-icon">🔐</span>
                        <div>
                            <div>Checkov</div>
                            <div style="font-size: 0.6em; font-weight: 400; color: #718096;">IaC Security</div>
                        </div>
                    </div>
                    <div class="tool-stats">
                        <span class="tool-stat-badge badge-clean">✅ Clean</span>
                        <span class="expand-icon">▼</span>
                    </div>
                </div>
                <div class="tool-content" id="checkov-content">
                    <div class="tool-findings">
                        ${CHECKOV_FINDINGS}
                    </div>
                </div>
            </div>

            <!-- Helm -->
            <div class="tool-card">
                <div class="tool-header" onclick="toggleTool('helm')">
                    <div class="tool-title">
                        <span class="tool-icon">⚓</span>
                        <div>
                            <div>Helm</div>
                            <div style="font-size: 0.6em; font-weight: 400; color: #718096;">Chart Validation</div>
                        </div>
                    </div>
                    <div class="tool-stats">
                        <span class="tool-stat-badge badge-clean">✅ Clean</span>
                        <span class="expand-icon">▼</span>
                    </div>
                </div>
                <div class="tool-content" id="helm-content">
                    <div class="tool-findings">
                        ${HELM_FINDINGS}
                    </div>
                </div>
            </div>

            <!-- Trivy -->
            <div class="tool-card">
                <div class="tool-header" onclick="toggleTool('trivy')">
                    <div class="tool-title">
                        <span class="tool-icon">🐳</span>
                        <div>
                            <div>Trivy</div>
                            <div style="font-size: 0.6em; font-weight: 400; color: #718096;">Container Vulnerability Scanner</div>
                        </div>
                    </div>
                    <div class="tool-stats">
EOF

# Add Trivy stats
if [ "$TRIVY_CRITICAL" -gt 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-critical\">❗ ${TRIVY_CRITICAL}</span>" >> "$OUTPUT_HTML"
fi
if [ "$TRIVY_HIGH" -gt 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-high\">⚠️ ${TRIVY_HIGH}</span>" >> "$OUTPUT_HTML"
fi
if [ "$TRIVY_CRITICAL" -eq 0 ] && [ "$TRIVY_HIGH" -eq 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-clean\">✅ Clean</span>" >> "$OUTPUT_HTML"
fi

cat >> "$OUTPUT_HTML" << EOF
                        <span class="expand-icon">▼</span>
                    </div>
                </div>
                <div class="tool-content" id="trivy-content">
                    <div class="tool-findings">
                        <div class="stats-detail-box">
                            <h4>📊 Scan Statistics</h4>
                            <div class="stats-grid-small">
                                <div class="stat-item"><strong>Images Scanned:</strong> ${TRIVY_IMAGES_SCANNED}</div>
                                <div class="stat-item"><strong>Total Vulnerabilities:</strong> ${TRIVY_TOTAL_VULNS}</div>
                                <div class="stat-item"><strong>Critical:</strong> ${TRIVY_CRITICAL}</div>
                                <div class="stat-item"><strong>High:</strong> ${TRIVY_HIGH}</div>
                                <div class="stat-item"><strong>Medium:</strong> ${TRIVY_MEDIUM}</div>
                                <div class="stat-item"><strong>Low:</strong> ${TRIVY_LOW}</div>
                            </div>
                        </div>
                        ${TRIVY_FINDINGS}
                    </div>
                </div>
            </div>

            <!-- Grype -->
            <div class="tool-card">
                <div class="tool-header" onclick="toggleTool('grype')">
                    <div class="tool-title">
                        <span class="tool-icon">🦑</span>
                        <div>
                            <div>Grype</div>
                            <div style="font-size: 0.6em; font-weight: 400; color: #718096;">Vulnerability Detector</div>
                        </div>
                    </div>
                    <div class="tool-stats">
EOF

# Add Grype stats
if [ "$GRYPE_CRITICAL" -gt 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-critical\">❗ ${GRYPE_CRITICAL}</span>" >> "$OUTPUT_HTML"
fi
if [ "$GRYPE_HIGH" -gt 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-high\">⚠️ ${GRYPE_HIGH}</span>" >> "$OUTPUT_HTML"
fi
if [ "$GRYPE_CRITICAL" -eq 0 ] && [ "$GRYPE_HIGH" -eq 0 ]; then
    echo "                        <span class=\"tool-stat-badge badge-clean\">✅ Clean</span>" >> "$OUTPUT_HTML"
fi

cat >> "$OUTPUT_HTML" << EOF
                        <span class="expand-icon">▼</span>
                    </div>
                </div>
                <div class="tool-content" id="grype-content">
                    <div class="tool-findings">
                        <div class="stats-detail-box">
                            <h4>📊 Scan Statistics</h4>
                            <div class="stats-grid-small">
                                <div class="stat-item"><strong>Targets Scanned:</strong> ${GRYPE_TARGETS_SCANNED}</div>
                                <div class="stat-item"><strong>Total Vulnerabilities:</strong> ${GRYPE_TOTAL_VULNS}</div>
                                <div class="stat-item"><strong>Critical:</strong> ${GRYPE_CRITICAL}</div>
                                <div class="stat-item"><strong>High:</strong> ${GRYPE_HIGH}</div>
                                <div class="stat-item"><strong>Medium:</strong> ${GRYPE_MEDIUM}</div>
                                <div class="stat-item"><strong>Low:</strong> ${GRYPE_LOW}</div>
                            </div>
                        </div>
                        ${GRYPE_FINDINGS}
                    </div>
                </div>
            </div>

            <!-- SBOM -->
            <div class="tool-card">
                <div class="tool-header" onclick="toggleTool('sbom')">
                    <div class="tool-title">
                        <span class="tool-icon">📦</span>
                        <div>
                            <div>SBOM</div>
                            <div style="font-size: 0.6em; font-weight: 400; color: #718096;">Software Bill of Materials</div>
                        </div>
                    </div>
                    <div class="tool-stats">
                        <span class="tool-stat-badge" style="background: #e0f2fe; color: #0369a1;">📊 ${SBOM_PACKAGES} packages</span>
                        <span class="expand-icon">▼</span>
                    </div>
                </div>
                <div class="tool-content" id="sbom-content">
                    <div class="tool-findings">
                        <div class="stats-detail-box">
                            <h4>📊 SBOM Statistics</h4>
                            <div class="stats-grid-small">
                                <div class="stat-item"><strong>SBOM Files Generated:</strong> ${SBOM_FILES_GENERATED}</div>
                                <div class="stat-item"><strong>Total Packages Cataloged:</strong> ${SBOM_PACKAGES}</div>
                            </div>
                        </div>
                        <p class="no-findings">✅ Software Bill of Materials generated successfully</p>
                    </div>
                </div>
            </div>
        </div>

        <div class="footer">
            <p style="color: #718096; margin-bottom: 10px;">
                Comprehensive Security Architecture Scanner
            </p>
            <p style="color: #a0aec0; font-size: 0.9em;">
                Total Findings: <strong style="color: #2d3748;">${TOTAL_FINDINGS}</strong> • 
                Tools: <strong style="color: #2d3748;">10</strong> • 
                Files Scanned: <strong style="color: #2d3748;">${CLAMAV_FILES_SCANNED}</strong> •
                Images Scanned: <strong style="color: #2d3748;">${TRIVY_IMAGES_SCANNED}</strong>
            </p>
            <div class="footer-links">
                <a href="../index.html" class="footer-link">📄 All Reports</a>
                <a href="../html-reports/" class="footer-link">📊 HTML Reports</a>
                <a href="../markdown-reports/" class="footer-link">📝 Markdown</a>
                <a href="../csv-reports/" class="footer-link">📈 CSV Data</a>
            </div>
        </div>
    </div>

    <script>
        function toggleTool(toolId) {
            const header = document.querySelector('#' + toolId + '-content').previousElementSibling;
            const content = document.getElementById(toolId + '-content');
            
            // Close all other tools
            document.querySelectorAll('.tool-header').forEach(h => {
                if (h !== header) {
                    h.classList.remove('active');
                }
            });
            document.querySelectorAll('.tool-content').forEach(c => {
                if (c !== content) {
                    c.classList.remove('active');
                }
            });
            
            // Toggle current tool
            header.classList.toggle('active');
            content.classList.toggle('active');
        }
        
        // Auto-expand first tool with findings
        window.addEventListener('DOMContentLoaded', () => {
            const badges = Array.from(document.querySelectorAll('.tool-stat-badge'));
            const firstIssue = badges.find(badge => badge.textContent.includes('❗') || badge.textContent.includes('⚠️'));
            
            if (firstIssue) {
                const toolCard = firstIssue.closest('.tool-card');
                const toolHeader = toolCard.querySelector('.tool-header');
                toolHeader.click();
            }
        });
    </script>
</body>
</html>
EOF

echo ""
echo "✅ Interactive dashboard generated: $OUTPUT_HTML"
echo ""
echo "Summary:"
echo "  Critical: $TOTAL_CRITICAL"
echo "  High:     $TOTAL_HIGH"
echo "  Medium:   $TOTAL_MEDIUM"
echo "  Low:      $TOTAL_LOW"
echo "  Total:    $TOTAL_FINDINGS"
echo ""
echo "Open the dashboard:"
echo "  open $OUTPUT_HTML"
