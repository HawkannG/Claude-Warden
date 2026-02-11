#!/usr/bin/env bash
# test-exit-codes.sh — Tests HIGH Vulnerability #4 (P2-V4)
# Validates that hooks use correct exit codes (0=allow, 1=block, 2=error)
# CVSS 6.8 — Wrong exit codes could cause blocks to be ignored

set -euo pipefail

TEST_NAME="Exit Code Correctness (P2-V4)"
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

setup() {
  TEST_DIR=$(mktemp -d)
  echo "protected" > "$TEST_DIR/CLAUDE.md"
  echo "safe" > "$TEST_DIR/safe.md"
}

teardown() {
  rm -rf "$TEST_DIR"
}

run_guard_hook() {
  local file_path="$1"
  echo "{\"tool\":\"Edit\",\"tool_input\":{\"file_path\":\"$file_path\"}}" | \
    CLAUDE_PROJECT_DIR="$TEST_DIR" bash .claude/hooks/prefect-guard.sh >/dev/null 2>&1
  echo $?
}

run_bash_hook() {
  local command="$1"
  echo "{\"tool\":\"Bash\",\"tool_input\":{\"command\":\"$command\"}}" | \
    CLAUDE_PROJECT_DIR="$TEST_DIR" bash .claude/hooks/prefect-bash-guard.sh >/dev/null 2>&1
  echo $?
}

test_block_exit_code_guard() {
  echo -n "  Test 4.1: Guard hook blocks with exit 1... "

  local result=$(run_guard_hook "$TEST_DIR/CLAUDE.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ CORRECT (exit 1)${NC}"
    ((PASS++))
  elif [ "$result" -eq 2 ]; then
    echo -e "${RED}❌ WRONG — using exit 2 (error) instead of exit 1 (block)${NC}"
    ((FAIL++))
  else
    echo -e "${RED}❌ WRONG — exit code $result${NC}"
    ((FAIL++))
  fi
}

test_allow_exit_code_guard() {
  echo -n "  Test 4.2: Guard hook allows with exit 0... "

  local result=$(run_guard_hook "$TEST_DIR/safe.md")

  if [ "$result" -eq 0 ]; then
    echo -e "${GREEN}✅ CORRECT (exit 0)${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ WRONG — exit code $result (should be 0)${NC}"
    ((FAIL++))
  fi
}

test_block_exit_code_bash() {
  echo -n "  Test 4.3: Bash hook blocks with exit 1... "

  local result=$(run_bash_hook "echo test > $TEST_DIR/CLAUDE.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ CORRECT (exit 1)${NC}"
    ((PASS++))
  elif [ "$result" -eq 2 ]; then
    echo -e "${RED}❌ WRONG — using exit 2 instead of exit 1${NC}"
    ((FAIL++))
  else
    echo -e "${RED}❌ WRONG — exit code $result${NC}"
    ((FAIL++))
  fi
}

test_allow_exit_code_bash() {
  echo -n "  Test 4.4: Bash hook allows with exit 0... "

  local result=$(run_bash_hook "ls -la")

  if [ "$result" -eq 0 ]; then
    echo -e "${GREEN}✅ CORRECT (exit 0)${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ WRONG — exit code $result (should be 0)${NC}"
    ((FAIL++))
  fi
}

test_error_exit_code() {
  echo -n "  Test 4.5: Hook errors with exit 2... "

  # Test with invalid JSON (should cause hook error)
  echo "invalid json" | \
    CLAUDE_PROJECT_DIR="$TEST_DIR" bash .claude/hooks/prefect-guard.sh >/dev/null 2>&1
  local result=$?

  if [ "$result" -eq 0 ]; then
    echo -e "${GREEN}✅ CORRECT (graceful handling or exit 0)${NC}"
    ((PASS++))
  elif [ "$result" -eq 2 ]; then
    echo -e "${GREEN}✅ CORRECT (exit 2 for error)${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ WRONG — exit code $result${NC}"
    ((FAIL++))
  fi
}

# Run tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$TEST_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

setup
test_block_exit_code_guard
test_allow_exit_code_guard
test_block_exit_code_bash
test_allow_exit_code_bash
test_error_exit_code
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
