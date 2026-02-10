#!/usr/bin/env bash
set -euo pipefail
# prefect-bash-guard.sh — PreToolUse hook for Bash commands
# Catches file write attempts via shell commands (echo >, cat >, tee, mv, cp, sed -i, etc.)
# This closes the biggest bypass: Claude using bash to write files instead of Write/Edit tools.
# Exit 0 = allow, Exit 2 = block

AUDIT_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/audit.log"
log_audit() {
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') [BASH-$1] $2" >> "$AUDIT_LOG" 2>/dev/null || true
}

INPUT=$(cat)

# Extract the bash command
if command -v jq &>/dev/null; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
else
  CMD=$(echo "$INPUT" | grep -oP '"command"\s*:\s*"\K[^"]+' | head -1 || echo "")
fi

if [ -z "$CMD" ]; then
  exit 0
fi

# ── DEFINE WRITE OPERATIONS ───────────────────────────
# Only match actual write/modify/delete operations, NOT reads
WRITE_OPS="(>|>>|tee\s|sed\s+-i|mv\s|cp\s|rm\s|chmod\s|chown\s|truncate\s|dd\s)"

# ── RULE 1: PROTECT GOVERNANCE FILES FROM BASH WRITES ──
PROTECTED_FILES="PREFECT-POLICY\.md|CLAUDE\.md|\.claude/hooks/|\.claude/settings\.json"

if echo "$CMD" | grep -qE "$WRITE_OPS" ; then
  if echo "$CMD" | grep -qE "$PROTECTED_FILES"; then
    log_audit "BLOCK" "Bash write to protected file: $CMD"
    echo "🛑 PREFECT BLOCK: Bash command targets a protected governance file." >&2
    echo "   → Cannot write to PREFECT-POLICY.md, CLAUDE.md, .claude/hooks/, or .claude/settings.json via bash." >&2
    echo "   → Suggest changes in chat. The human will make the edit." >&2
    exit 2
  fi
fi

# ── RULE 2: BLOCK HOOK SELF-MODIFICATION ───────────────
if echo "$CMD" | grep -qE "prefect-(guard|post-check|session-end|audit|bash-guard)\.sh" ; then
  if echo "$CMD" | grep -qE "$WRITE_OPS|nano|vim|vi\s|edit" ; then
    log_audit "BLOCK" "Bash attempt to modify hook: $CMD"
    echo "🛑 PREFECT BLOCK: Cannot modify hook scripts via bash." >&2
    exit 2
  fi
fi

# ── RULE 3: BLOCK SETTINGS.JSON MODIFICATION ──────────
if echo "$CMD" | grep -qE "settings\.json" ; then
  if echo "$CMD" | grep -qE "$WRITE_OPS" ; then
    log_audit "BLOCK" "Bash attempt to modify settings.json: $CMD"
    echo "🛑 PREFECT BLOCK: Cannot modify .claude/settings.json via bash." >&2
    exit 2
  fi
fi

# ── RULE 4: BLOCK FORBIDDEN DIRECTORIES VIA BASH ──────
FORBIDDEN_DIRS="(^|/)temp(/|\s|$)|(^|/)tmp(/|\s|$)|(^|/)misc(/|\s|$)|(^|/)stuff(/|\s|$)|(^|/)old(/|\s|$)|(^|/)backup(/|\s|$)|(^|/)bak(/|\s|$)|(^|/)scratch(/|\s|$)|(^|/)junk(/|\s|$)|(^|/)archive(/|\s|$)"
if echo "$CMD" | grep -qE "(mkdir|touch|cat\s|echo\s|tee\s|cp\s|mv\s)" ; then
  if echo "$CMD" | grep -qiE "$FORBIDDEN_DIRS"; then
    log_audit "BLOCK" "Bash create in forbidden directory: $CMD"
    echo "🛑 PREFECT BLOCK: Bash command targets a forbidden directory." >&2
    exit 2
  fi
fi

# ── RULE 5: BLOCK GIT COMMIT --NO-VERIFY ──────────────
if echo "$CMD" | grep -qE "git\s+commit" ; then
  if echo "$CMD" | grep -qE "\-\-no-verify"; then
    log_audit "BLOCK" "git commit --no-verify blocked: $CMD"
    echo "🛑 PREFECT BLOCK: --no-verify is forbidden. Run tests first." >&2
    exit 2
  fi
fi

# ── All checks passed ─────────────────────────────────
exit 0
