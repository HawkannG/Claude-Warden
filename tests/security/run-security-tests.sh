#!/usr/bin/env bash
# run-security-tests.sh — Master test runner for Prefect security suite
# Runs all security tests and produces summary report

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_TESTS=0

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🔐 Prefect AI Governance Framework — Security Test Suite${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Running comprehensive security tests for v6.0 hardening..."
echo ""

# Check prerequisites
if ! command -v jq &>/dev/null; then
  echo -e "${RED}❌ ERROR: jq is required but not installed${NC}"
  echo "   Install: brew install jq (macOS) or sudo apt-get install jq (Linux)"
  exit 2
fi

if [ ! -f ".claude/hooks/prefect-guard.sh" ]; then
  echo -e "${RED}❌ ERROR: Hook scripts not found${NC}"
  echo "   Run from project root directory"
  exit 2
fi

# Make test scripts executable
chmod +x tests/security/*.sh 2>/dev/null || true

# Run each test
run_test() {
  local test_file="$1"
  local test_name=$(basename "$test_file")

  ((TOTAL_TESTS++))

  if bash "$test_file"; then
    echo ""
    ((TOTAL_PASS++))
    return 0
  else
    echo ""
    ((TOTAL_FAIL++))
    return 1
  fi
}

# Test suite
run_test "tests/security/test-symlink-attack.sh"
run_test "tests/security/test-path-traversal.sh"
run_test "tests/security/test-exit-codes.sh"
run_test "tests/security/test-command-injection.sh"

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📊 Security Test Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total test suites: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$TOTAL_PASS${NC}"
echo -e "Failed: ${RED}$TOTAL_FAIL${NC}"
echo ""

if [ $TOTAL_FAIL -gt 0 ]; then
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}❌ SECURITY TEST SUITE FAILED${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Critical vulnerabilities detected. Do not submit to awesome-claude-code"
  echo "until all tests pass."
  echo ""
  exit 1
else
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}✅ SECURITY TEST SUITE PASSED${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "All critical security vulnerabilities are mitigated."
  echo "Framework is ready for production use."
  echo ""
  echo "Note: Review test-command-injection.sh warnings for defense-in-depth"
  echo "improvements (whitelist approach recommended)."
  echo ""
  exit 0
fi
