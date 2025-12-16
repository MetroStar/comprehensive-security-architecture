#!/bin/bash

# Test runner script for shell script unit tests
# Runs all bats test files in the tests/shell directory

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Shell Script Unit Test Runner${NC}"
echo -e "${BLUE}=========================================${NC}"
echo

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${RED}❌ Error: bats is not installed${NC}"
    echo "Please install bats-core: https://github.com/bats-core/bats-core"
    exit 1
fi

echo -e "${GREEN}✅ bats is installed: $(bats --version)${NC}"
echo

# Count test files
TEST_FILES=$(find "$TEST_DIR" -name "*.bats" | wc -l)
echo -e "${BLUE}Found $TEST_FILES test files${NC}"
echo

# Run all tests
echo -e "${YELLOW}Running all unit tests...${NC}"
echo

# Run bats with all test files
if bats "$TEST_DIR"/*.bats; then
    echo
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    exit 0
else
    echo
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}❌ Some tests failed${NC}"
    echo -e "${RED}=========================================${NC}"
    exit 1
fi
