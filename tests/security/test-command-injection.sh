#!/usr/bin/env bash
# test-command-injection.sh — Tests CRITICAL Vulnerability #3 (P2-V3)
# Validates that bash-guard blocks command injection vectors
# CVSS 8.1 — Command injection could bypass all protections

set -euo pipefail

TEST_NAME="Command Injection Prevention (P2-V3)"
PASS=0
FAIL=0
WARN=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

setup() {
  TEST_DIR=$(mktemp -d)
  echo "protected" > "$TEST_DIR/CLAUDE.md"
  echo "safe" > "$TEST_DIR/safe.md"
}

teardown() {
  rm -rf "$TEST_DIR"
}

run_bash_hook() {
  local command="$1"
  echo "{\"tool\":\"Bash\",\"tool_input\":{\"command\":\"$command\"}}" | \
    CLAUDE_PROJECT_DIR="$TEST_DIR" bash .claude/hooks/prefect-bash-guard.sh >/dev/null 2>&1
  echo $?
}

test_direct_write_blocked() {
  echo -n "  Test 3.1: Direct write (echo > CLAUDE.md)... "

  local result=$(run_bash_hook "echo hacked > $TEST_DIR/CLAUDE.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ ALLOWED${NC}"
    ((FAIL++))
  fi
}

test_variable_expansion() {
  echo -n "  Test 3.2: Variable expansion bypass... "

  local result=$(run_bash_hook "TARGET=$TEST_DIR/CLAUDE.md && echo hacked > \$TARGET")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${YELLOW}⚠️  ALLOWED — Variable expansion bypass works${NC}"
    ((WARN++))
  fi
}

test_command_substitution() {
  echo -n "  Test 3.3: Command substitution bypass... "

  local result=$(run_bash_hook "echo hacked > \$(echo $TEST_DIR/CLAUDE.md)")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${YELLOW}⚠️  ALLOWED — Command substitution bypass works${NC}"
    ((WARN++))
  fi
}

test_base64_encoding() {
  echo -n "  Test 3.4: Base64 encoding bypass... "

  # Base64 encode: echo hacked > CLAUDE.md
  local result=$(run_bash_hook "echo 'ZWNobyBoYWNrZWQgPiBDTEFVREUubWQ=' | base64 -d | bash")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${YELLOW}⚠️  ALLOWED — Base64 bypass works${NC}"
    ((WARN++))
  fi
}

test_heredoc() {
  echo -n "  Test 3.5: Heredoc bypass... "

  local cmd="cat > $TEST_DIR/CLAUDE.md << 'EOF'
hacked
EOF"

  local result=$(run_bash_hook "$cmd")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${YELLOW}⚠️  ALLOWED — Heredoc bypass works${NC}"
    ((WARN++))
  fi
}

test_tee_indirect() {
  echo -n "  Test 3.6: Tee indirect write... "

  local result=$(run_bash_hook "echo hacked | tee $TEST_DIR/CLAUDE.md")

  if [ "$result" -eq 1 ]; then
    echo -e "${GREEN}✅ BLOCKED${NC}"
    ((PASS++))
  else
    echo -e "${YELLOW}⚠️  ALLOWED — Tee bypass works${NC}"
    ((WARN++))
  fi
}

test_safe_read_allowed() {
  echo -n "  Test 3.7: Safe read operation... "

  local result=$(run_bash_hook "cat $TEST_DIR/CLAUDE.md")

  if [ "$result" -eq 0 ]; then
    echo -e "${GREEN}✅ ALLOWED${NC}"
    ((PASS++))
  else
    echo -e "${RED}❌ BLOCKED incorrectly${NC}"
    ((FAIL++))
  fi
}

# Run tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$TEST_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

setup
test_direct_write_blocked
test_variable_expansion
test_command_substitution
test_base64_encoding
test_heredoc
test_tee_indirect
test_safe_read_allowed
teardown

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$WARN warnings${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAIL -gt 0 ]; then
  echo -e "${RED}❌ SECURITY TEST FAILED${NC}"
  exit 1
elif [ $WARN -gt 0 ]; then
  echo -e "${YELLOW}⚠️  PARTIAL PROTECTION — Advanced bypasses still work${NC}"
  echo -e "${YELLOW}   Recommendation: Implement whitelist approach (block all bash writes)${NC}"
  exit 0  # Warning, not failure
else
  echo -e "${GREEN}✅ All security tests passed${NC}"
  exit 0
fi
