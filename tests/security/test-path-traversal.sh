#!/usr/bin/env bash
# test-path-traversal.sh — Tests CRITICAL Vulnerability #2 (P2-V2)
# Validates that hooks prevent path traversal attacks
# CVSS 7.9 — Path traversal could allow writing outside project directory

set -euo pipefail

TEST_NAME="Path Traversal Prevention (P2-V2)"
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

setup() {
  TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/project/src"
  echo "protected" > "$TEST_DIR/project/CLAUDE.md"
  echo "safe" > "$TEST_DIR/project/src/app.ts"
}

teardown() {
  rm -rf "$TEST_DIR"
}

run_hook() {
  local file_path="$1"
  echo "{\"tool\":\"Edit\",\"tool_input\":{\"file_path\":\"$file_path\"}}" | \
    CLAUDE_PROJECT_DIR="$TEST_DIR/project" bash .claude/hooks/prefect-guard.sh >/dev/null 2>&1
  echo $?
}

test_literal_dotdot_blocked() {
  echo -n "  Test 2.1: Literal ../ traversal... "

  local result=$(run_hook "$TEST_DIR/project/src/../../etc/passwd")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED — path traversal works${NC}"
    ((FAIL++))
  fi
}

test_encoded_dotdot() {
  echo -n "  Test 2.2: URL-encoded ../ (%2e%2e/)... "

  # Note: This tests if hook normalizes before checking
  local result=$(run_hook "$TEST_DIR/project/src/%2e%2e/CLAUDE.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED — encoded traversal bypass${NC}"
    ((FAIL++))
  fi
}

test_absolute_path_outside_project() {
  echo -n "  Test 2.3: Absolute path outside project... "

  local result=$(run_hook "/etc/passwd")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED — can write outside project${NC}"
    ((FAIL++))
  fi
}

test_canonical_path_inside_project() {
  echo -n "  Test 2.4: Valid file inside project... "

  local result=$(run_hook "$TEST_DIR/project/src/app.ts")

  if [ "$result" -eq 0 ]; then
    echo -e "${GREEN}✅ ALLOWED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ BLOCKED incorrectly${NC}"
    ((FAIL++))
  fi
}

test_relative_path_to_protected_file() {
  echo -n "  Test 2.5: Relative path to protected file... "

  # From src/, try to access ../CLAUDE.md
  local result=$(run_hook "$TEST_DIR/project/src/../CLAUDE.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED — relative path bypass${NC}"
    ((FAIL++))
  fi
}

test_dot_slash_paths() {
  echo -n "  Test 2.6: ./ prefix paths... "

  local result=$(run_hook "$TEST_DIR/project/./CLAUDE.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED — ./ bypass${NC}"
    ((FAIL++))
  fi
}

# Run tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$TEST_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

setup
test_literal_dotdot_blocked
test_encoded_dotdot
test_absolute_path_outside_project
test_canonical_path_inside_project
test_relative_path_to_protected_file
test_dot_slash_paths
teardown

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAIL -gt 0 ]; then
  echo -e "${RED}❌ SECURITY TEST FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}✅ All security tests passed${NC}"
  exit 0
fi
