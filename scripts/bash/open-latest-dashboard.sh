#!/bin/bash

# Open Latest Security Dashboard
# Automatically finds and opens the most recent scan's dashboard

# Color definitions
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Find latest scan
SCANS_DIR="$WORKSPACE_ROOT/scans"
LATEST_SCAN=$(find "$SCANS_DIR" -maxdepth 1 -type d -name "*_*_*" 2>/dev/null | sort -r | head -n 1)

if [[ -z "$LATEST_SCAN" ]]; then
    echo -e "${RED}❌ No scan directories found in $SCANS_DIR${NC}"
    echo -e "${YELLOW}Run a scan first using: ./run-target-security-scan.sh <target> <mode>${NC}"
    exit 1
fi

DASHBOARD_PATH="$LATEST_SCAN/consolidated-reports/dashboards/security-dashboard.html"

if [[ ! -f "$DASHBOARD_PATH" ]]; then
    echo -e "${YELLOW}⚠️  Dashboard not found. Regenerating...${NC}"
    SCAN_DIR="$LATEST_SCAN" "$SCRIPT_DIR/generate-security-dashboard.sh"
    
    if [[ ! -f "$DASHBOARD_PATH" ]]; then
        echo -e "${RED}❌ Failed to generate dashboard${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Opening latest scan dashboard${NC}"
echo -e "${CYAN}📊 Scan: $(basename "$LATEST_SCAN")${NC}"
echo -e "${CYAN}📁 Path: $DASHBOARD_PATH${NC}"
echo ""

# Open in default browser
open "$DASHBOARD_PATH"
