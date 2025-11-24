#!/bin/bash

# Generate Security Dashboard from findings summary
# This script creates a comprehensive HTML dashboard using the security-findings-summary.json

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Input parameters
FINDINGS_FILE="${1:-}"
OUTPUT_HTML="${2:-}"

if [ -z "$FINDINGS_FILE" ] || [ -z "$OUTPUT_HTML" ]; then
    echo "Usage: $0 <findings-json-file> <output-html-file>"
    exit 1
fi

if [ ! -f "$FINDINGS_FILE" ]; then
    echo "Error: Findings file not found: $FINDINGS_FILE"
    exit 1
fi

# Extract data using jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Parse JSON data
SCAN_ID=$(jq -r '.summary.scan_id' "$FINDINGS_FILE")
TARGET_DIR=$(jq -r '.summary.target_directory' "$FINDINGS_FILE")
SCAN_TIMESTAMP=$(jq -r '.summary.scan_timestamp' "$FINDINGS_FILE")
TOTAL_CRITICAL=$(jq -r '.summary.total_critical' "$FINDINGS_FILE")
TOTAL_HIGH=$(jq -r '.summary.total_high' "$FINDINGS_FILE")
TOTAL_MEDIUM=$(jq -r '.summary.total_medium' "$FINDINGS_FILE")
TOTAL_LOW=$(jq -r '.summary.total_low' "$FINDINGS_FILE")
TOOLS_COUNT=$(jq -r '.summary.tools_analyzed | length' "$FINDINGS_FILE")

# Get first few critical findings for display
CRITICAL_FINDINGS=$(jq -r '.critical_findings[0:3] | to_entries | map("
<div class=\"finding-item critical-finding\">
    <div class=\"finding-header\">
        <span class=\"finding-tool\">" + .value.tool + "</span>
        <span class=\"finding-severity severity-critical\">CRITICAL" + (if .value.verified then " <span class=\"verified-badge\">VERIFIED</span>" else "" end) + "</span>
    </div>
    <div class=\"finding-description\">
        ⚠️ " + .value.description + "
    </div>
    <div class=\"finding-details\">
        <p>📁 File: <code>" + (.value.file_path // .value.file // "N/A") + "</code></p>" + 
        (if .value.line_number then "<p>📍 Line: <code>" + (.value.line_number | tostring) + "</code></p>" else "" end) +
        (if .value.detector then "<p>🔍 Detector: " + .value.detector + "</p>" else "" end) +
        (if .value.verified then "<p>✅ Status: <strong style=\"color: #e53e3e;\">VERIFIED - Active credentials detected</strong></p>" else "" end) +
        (if .value.priority then "<p style=\"margin-top: 10px;\"><strong>Priority:</strong> " + .value.priority + "</p>" else "" end) +
        (if .value.impact then "<p><strong>Impact:</strong> " + .value.impact + "</p>" else "" end) +
    "</div>
</div>
") | join("\n")' "$FINDINGS_FILE")

# Get timestamp for display
DISPLAY_DATE=$(date "+%B %d, %Y at %I:%M %p")

# Determine if there are critical findings for alert banner
SHOW_ALERT=""
if [ "$TOTAL_CRITICAL" -gt 0 ]; then
    SHOW_ALERT="
        <div class=\"alert-banner\">
            <h2>⚠️ CRITICAL SECURITY ALERT</h2>
            <p><strong>${TOTAL_CRITICAL} Critical Findings</strong> detected that require immediate action!</p>
        </div>
"
fi

# Generate HTML dashboard
cat > "$OUTPUT_HTML" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Dashboard - ${SCAN_ID}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        .alert-banner {
            background: linear-gradient(135deg, #e53e3e 0%, #c53030 100%);
            color: white;
            padding: 20px;
            border-radius: 12px;
            margin-bottom: 20px;
            box-shadow: 0 4px 20px rgba(229, 62, 62, 0.3);
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.02); }
        }
        .alert-banner h2 {
            font-size: 1.5em;
            margin-bottom: 10px;
        }
        .header {
            background: white;
            border-radius: 16px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
        }
        .header h1 {
            color: #2d3748;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header p {
            color: #718096;
            font-size: 1.1em;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            transition: transform 0.2s;
        }
        .stat-card:hover {
            transform: translateY(-5px);
        }
        .stat-number {
            font-size: 3em;
            font-weight: bold;
            margin: 10px 0;
        }
        .stat-label {
            color: #718096;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .critical { color: #e53e3e; }
        .high { color: #dd6b20; }
        .medium { color: #d69e2e; }
        .low { color: #38a169; }
        
        .findings-section {
            background: white;
            border-radius: 12px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            max-height: 600px;
            overflow-y: auto;
        }
        .findings-section h2 {
            color: #2d3748;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e2e8f0;
            position: sticky;
            top: 0;
            background: white;
            z-index: 10;
        }
        .finding-item {
            background: #f7fafc;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 4px;
        }
        .finding-item.critical-finding {
            border-left: 4px solid #e53e3e;
            background: #fff5f5;
        }
        .finding-item.high-finding {
            border-left: 4px solid #dd6b20;
            background: #fffaf0;
        }
        .finding-item.medium-finding {
            border-left: 4px solid #d69e2e;
            background: #fef5e7;
        }
        .finding-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
            flex-wrap: wrap;
            gap: 10px;
        }
        .finding-tool {
            background: #667eea;
            color: white;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }
        .finding-severity {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }
        .severity-critical {
            background: #fed7d7;
            color: #c53030;
        }
        .severity-high {
            background: #feebc8;
            color: #c05621;
        }
        .severity-medium {
            background: #fef5e7;
            color: #d69e2e;
        }
        .finding-description {
            color: #2d3748;
            margin-bottom: 8px;
            font-weight: 600;
        }
        .finding-details {
            font-size: 0.9em;
            color: #4a5568;
            margin-top: 8px;
        }
        .finding-details code {
            background: #edf2f7;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Monaco', 'Courier New', monospace;
            font-size: 0.85em;
            word-break: break-all;
        }
        .verified-badge {
            display: inline-block;
            background: #e53e3e;
            color: white;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.75em;
            font-weight: bold;
            margin-left: 10px;
        }
        .links-section {
            background: white;
            border-radius: 12px;
            padding: 30px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }
        .links-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        .link-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-decoration: none;
            display: block;
            transition: transform 0.2s;
        }
        .link-card:hover {
            transform: scale(1.05);
        }
        .link-card h3 {
            margin-bottom: 8px;
        }
        .link-card p {
            font-size: 0.9em;
            opacity: 0.9;
        }
        .summary-box {
            text-align: center;
            padding: 40px;
            color: #718096;
        }
        .summary-box .icon {
            font-size: 3em;
            margin-bottom: 10px;
        }
        .summary-box p {
            margin-top: 10px;
        }
        .timestamp {
            color: #718096;
            font-size: 0.9em;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        ${SHOW_ALERT}

        <div class="header">
            <h1>🛡️ Security Dashboard</h1>
            <p><strong>Scan ID:</strong> ${SCAN_ID}</p>
            <p><strong>Target:</strong> ${TARGET_DIR}</p>
            <p class="timestamp">Generated: ${DISPLAY_DATE}</p>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Critical</div>
                <div class="stat-number critical">${TOTAL_CRITICAL}</div>
                <p>Requires immediate action</p>
            </div>
            <div class="stat-card">
                <div class="stat-label">High</div>
                <div class="stat-number high">${TOTAL_HIGH}</div>
                <p>High priority issues</p>
            </div>
            <div class="stat-card">
                <div class="stat-label">Medium</div>
                <div class="stat-number medium">${TOTAL_MEDIUM}</div>
                <p>Medium priority issues</p>
            </div>
            <div class="stat-card">
                <div class="stat-label">Low</div>
                <div class="stat-number low">${TOTAL_LOW}</div>
                <p>Low priority issues</p>
            </div>
        </div>
EOF

# Add critical findings section if any exist
if [ "$TOTAL_CRITICAL" -gt 0 ]; then
    cat >> "$OUTPUT_HTML" << EOF

        <div class="findings-section">
            <h2>🚨 Critical Findings (${TOTAL_CRITICAL}) - IMMEDIATE ACTION REQUIRED</h2>
            
            ${CRITICAL_FINDINGS}

EOF
    
    # Add note about additional findings if more than 3
    if [ "$TOTAL_CRITICAL" -gt 3 ]; then
        REMAINING=$((TOTAL_CRITICAL - 3))
        cat >> "$OUTPUT_HTML" << EOF
            <div style="text-align: center; padding: 20px; background: #fff5f5; border-radius: 8px; margin-top: 15px;">
                <p style="color: #e53e3e; font-weight: bold;">
                    ⚠️ ${REMAINING} additional critical findings detected
                </p>
                <p style="color: #718096; margin-top: 10px;">
                    <a href="../security-findings-summary.json" style="color: #667eea;">View complete findings in JSON report</a>
                </p>
            </div>
EOF
    fi
    
    cat >> "$OUTPUT_HTML" << EOF
        </div>
EOF
fi

# Add high findings section if any exist
if [ "$TOTAL_HIGH" -gt 0 ]; then
    cat >> "$OUTPUT_HTML" << EOF

        <div class="findings-section">
            <h2>🔶 High Priority Findings (${TOTAL_HIGH})</h2>
            <div class="summary-box">
                <div class="icon">📊</div>
                <p style="font-size: 1.2em; color: #2d3748; margin-bottom: 10px;">${TOTAL_HIGH} High Severity Issues Detected</p>
                <p>Review detailed findings in individual tool reports</p>
                <p style="margin-top: 15px;">
                    <a href="../html-reports/" style="color: #667eea; text-decoration: none; font-weight: 600;">Browse HTML Reports →</a>
                </p>
            </div>
        </div>
EOF
fi

# Add medium findings section if any exist
if [ "$TOTAL_MEDIUM" -gt 0 ]; then
    cat >> "$OUTPUT_HTML" << EOF

        <div class="findings-section">
            <h2>⚠️ Medium Priority Findings (${TOTAL_MEDIUM})</h2>
            <div class="summary-box">
                <div class="icon">📋</div>
                <p style="font-size: 1.2em; color: #2d3748; margin-bottom: 10px;">${TOTAL_MEDIUM} Medium Severity Issues Detected</p>
                <p>Review detailed findings in individual tool reports</p>
                <p style="margin-top: 15px;">
                    <a href="../html-reports/" style="color: #667eea; text-decoration: none; font-weight: 600;">Browse HTML Reports →</a>
                </p>
            </div>
        </div>
EOF
fi

# Add success message if no findings
if [ "$TOTAL_CRITICAL" -eq 0 ] && [ "$TOTAL_HIGH" -eq 0 ] && [ "$TOTAL_MEDIUM" -eq 0 ] && [ "$TOTAL_LOW" -eq 0 ]; then
    cat >> "$OUTPUT_HTML" << EOF

        <div class="findings-section">
            <div class="summary-box">
                <div class="icon">✅</div>
                <p style="font-size: 1.5em; color: #38a169; font-weight: bold;">No Security Issues Found</p>
                <p style="margin-top: 10px;">All security scans completed successfully with no findings.</p>
            </div>
        </div>
EOF
fi

# Complete the HTML
cat >> "$OUTPUT_HTML" << EOF

        <div class="links-section">
            <h2>📄 Detailed Reports</h2>
            <div class="links-grid">
                <a href="../html-reports/" class="link-card">
                    <h3>📊 HTML Reports</h3>
                    <p>Browse detailed HTML reports for each security tool</p>
                </a>
                <a href="../markdown-reports/" class="link-card">
                    <h3>📝 Markdown Reports</h3>
                    <p>View markdown-formatted analysis reports</p>
                </a>
                <a href="../csv-reports/" class="link-card">
                    <h3>📈 CSV Reports</h3>
                    <p>Download CSV data for spreadsheet analysis</p>
                </a>
                <a href="../security-findings-summary.json" class="link-card">
                    <h3>🔍 JSON Summary</h3>
                    <p>Access raw JSON data for programmatic analysis</p>
                </a>
                <a href="../index.html" class="link-card">
                    <h3>🏠 Report Index</h3>
                    <p>Navigate all available security reports</p>
                </a>
            </div>
        </div>

        <div style="background: white; border-radius: 12px; padding: 20px; margin-top: 20px; text-align: center; box-shadow: 0 4px 20px rgba(0,0,0,0.08);">
            <p style="color: #718096;">
                Generated by Comprehensive Security Architecture Scanner<br>
                <small>Scan completed on ${DISPLAY_DATE} • Total findings: $((TOTAL_CRITICAL + TOTAL_HIGH + TOTAL_MEDIUM + TOTAL_LOW)) issues across ${TOOLS_COUNT} tool configurations</small>
            </p>
        </div>
    </div>
</body>
</html>
EOF

echo "✓ Dashboard generated: $OUTPUT_HTML"
