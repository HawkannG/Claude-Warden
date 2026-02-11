#!/usr/bin/env bash
# test-symlink-attack.sh — Tests CRITICAL Vulnerability #1 (P2-V1)
# Validates that hooks resolve symlinks before checking protected files
# CVSS 8.4 — Symlink bypass could allow editing governance files

set -euo pipefail

TEST_NAME="Symlink Attack Prevention (P2-V1)"
PASS=0
FAIL=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

setup() {
  TEST_DIR=$(mktemp -d)
  echo "protected content" > "$TEST_DIR/CLAUDE.md"
  echo "protected policy" > "$TEST_DIR/PREFECT-POLICY.md"
  mkdir -p "$TEST_DIR/.claude/hooks"
  echo "normal file" > "$TEST_DIR/safe.md"
}

teardown() {
  rm -rf "$TEST_DIR"
}

run_hook() {
  local file_path="$1"
  echo "{\"tool\":\"Edit\",\"tool_input\":{\"file_path\":\"$file_path\"}}" | \
    CLAUDE_PROJECT_DIR="$TEST_DIR" bash .claude/hooks/prefect-guard.sh >/dev/null 2>&1
  echo $?
}

test_direct_edit_blocked() {
  echo -n "  Test 1.1: Direct edit of CLAUDE.md... "

  local result=$(run_hook "$TEST_DIR/CLAUDE.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED (exit code: $result)${NC}"
    ((FAIL++))
  fi
}

test_symlink_single_level() {
  echo -n "  Test 1.2: Edit via symlink (sneaky.md -> CLAUDE.md)... "

  ln -s CLAUDE.md "$TEST_DIR/sneaky.md"
  local result=$(run_hook "$TEST_DIR/sneaky.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED (symlink resolved)${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED — CRITICAL VULNERABILITY${NC}"
    echo -e "${RED}   Symlink bypass works! Hook checks symlink name, not target.${NC}"
    ((FAIL++))
  fi

  rm "$TEST_DIR/sneaky.md"
}

test_symlink_nested() {
  echo -n "  Test 1.3: Edit via nested symlink (a -> b -> CLAUDE.md)... "

  ln -s CLAUDE.md "$TEST_DIR/target.md"
  ln -s target.md "$TEST_DIR/alias.md"
  local result=$(run_hook "$TEST_DIR/alias.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED (nested symlink resolved)${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED — nested symlink bypass${NC}"
    ((FAIL++))
  fi

  rm "$TEST_DIR/alias.md" "$TEST_DIR/target.md"
}

test_symlink_to_hooks() {
  echo -n "  Test 1.4: Edit hook via symlink... "

  echo "#!/bin/bash" > "$TEST_DIR/.claude/hooks/prefect-guard.sh"
  ln -s .claude/hooks/prefect-guard.sh "$TEST_DIR/innocent.sh"
  local result=$(run_hook "$TEST_DIR/innocent.sh")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED (hook protected via symlink)${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED — hooks vulnerable via symlink${NC}"
    ((FAIL++))
  fi

  rm "$TEST_DIR/innocent.sh"
}

test_safe_file_allowed() {
  echo -n "  Test 1.5: Edit safe file (should allow)... "

  local result=$(run_hook "$TEST_DIR/safe.md")

  if [ "$result" -eq 0 ]; then
    echo -e "${GREEN}✅ ALLOWED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ BLOCKED incorrectly (exit code: $result)${NC}"
    ((FAIL++))
  fi
}

# Run tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$TEST_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

setup
test_direct_edit_blocked
test_symlink_single_level
test_symlink_nested
test_symlink_to_hooks
test_safe_file_allowed
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
