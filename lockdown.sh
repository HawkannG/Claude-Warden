#!/usr/bin/env bash
# lockdown.sh — Toggle write protection on Prefect governance files
# Usage: ./lockdown.sh lock | unlock | status

set -euo pipefail

GOVERNANCE_FILES=(
  "CLAUDE.md"
  "PREFECT-POLICY.md"
  ".claude/hooks/prefect-guard.sh"
  ".claude/hooks/prefect-bash-guard.sh"
  ".claude/hooks/prefect-post-check.sh"
  ".claude/hooks/prefect-session-end.sh"
  ".claude/hooks/prefect-audit.sh"
  ".claude/settings.json"
)

lock() {
  echo "🔒 Locking governance files..."
  for f in "${GOVERNANCE_FILES[@]}"; do
    if [ -f "$f" ]; then
      chmod -w "$f"
      echo "   ✅ $f"
    else
      echo "   ⚠️  $f not found — skipping"
    fi
  done
  echo "Done. Claude cannot modify these files."
}

unlock() {
  echo "🔓 Unlocking governance files for editing..."
  for f in "${GOVERNANCE_FILES[@]}"; do
    if [ -f "$f" ]; then
      chmod +w "$f"
      echo "   ✅ $f"
    else
      echo "   ⚠️  $f not found — skipping"
    fi
  done
  echo "Done. Remember to lock again after editing: ./lockdown.sh lock"
}

status() {
  echo "📋 Governance file permissions:"
  for f in "${GOVERNANCE_FILES[@]}"; do
    if [ -f "$f" ]; then
      perms=$(ls -la "$f" | awk '{print $1}')
      if echo "$perms" | grep -q "w"; then
        echo "   🔓 $perms  $f"
      else
        echo "   🔒 $perms  $f"
      fi
    else
      echo "   ❌ $f — not found"
    fi
  done
}

case "${1:-help}" in
  lock)   lock ;;
  unlock) unlock ;;
  status) status ;;
  *)
    echo "Usage: ./lockdown.sh [lock|unlock|status]"
    echo "  lock   — Remove write permission (protect from Claude)"
    echo "  unlock — Restore write permission (for human editing)"
    echo "  status — Show current permissions"
    ;;
esac
