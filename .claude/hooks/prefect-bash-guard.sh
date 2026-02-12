#!/usr/bin/env bash
set -euo pipefail
# prefect-bash-guard.sh — PreToolUse hook for Bash commands
# Catches file write attempts via shell commands (echo >, cat >, tee, mv, cp, sed -i, etc.)
# This closes the biggest bypass: Claude using bash to write files instead of Write/Edit tools.
# Exit 0 = allow, Exit 1 = block, Exit 2 = error

AUDIT_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/audit.log"
log_audit() {
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') [BASH-$1] $2" >> "$AUDIT_LOG" 2>/dev/null || true
}

INPUT=$(cat)

# Extract the bash command — jq is required (FIX V5: No unsafe grep fallback)
if ! command -v jq &>/dev/null; then
  echo "🛑 PREFECT ERROR: jq is required for hook operation" >&2
  echo "   Install: brew install jq (macOS) or sudo apt-get install jq (Linux)" >&2
  exit 2  # Error, not block
fi

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

if [ -z "$CMD" ]; then
  exit 0
fi

# ── RULE 1: BLOCK DANGEROUS CONSTRUCTS ────────────────
# High-confidence patterns that are rarely legitimate in project work
# Catches: base64 decode piped, eval with strings, source from /dev/
if echo "$CMD" | grep -qE '(base64\s+-d.*\||eval\s+["'\''`]|source\s+/dev/)'; then
  log_audit "BLOCK" "Dangerous bash construct: $CMD"
  echo "🛑 PREFECT BLOCK: Forbidden bash construct detected." >&2
  echo "   → Blocked patterns: base64 -d (piped), eval (with strings), source /dev/" >&2
  exit 1
fi

# ── RULE 2: PROTECT GOVERNANCE FILES FROM BASH WRITES ──
# Block any bash command that writes to protected files
PROTECTED_FILES="PREFECT-POLICY\.md|CLAUDE\.md|lockdown\.sh|\.claude/hooks/|\.claude/settings\.json"

# Check for write operations targeting protected files
# Catches: echo/cat/tee writing to file, sed -i editing, mv/cp overwriting, rm deleting
if echo "$CMD" | grep -qE "(>|>>|tee|sed\s+-i|mv\s|cp\s|rm\s|chmod|chown)" ; then
  if echo "$CMD" | grep -qE "$PROTECTED_FILES"; then
    log_audit "BLOCK" "Bash write to protected file: $CMD"
    echo "🛑 PREFECT BLOCK: Bash command targets a protected governance file." >&2
    echo "   → Cannot write to PREFECT-POLICY.md, CLAUDE.md, lockdown.sh, .claude/hooks/, or .claude/settings.json via bash." >&2
    echo "   → Suggest changes in chat. The human will make the edit." >&2
    exit 1
  fi
fi

# ── RULE 3: BLOCK HOOK SELF-MODIFICATION ───────────────
# Extra paranoid check — any command referencing hook scripts with write intent
if echo "$CMD" | grep -qE "prefect-(guard|post-check|session-end|audit|bash-guard)\.sh" ; then
  if echo "$CMD" | grep -qE "(>|>>|tee|sed\s+-i|mv\s|cp\s|rm\s|chmod|chown|nano|vim|vi\s|emacs|edit)" ; then
    log_audit "BLOCK" "Bash attempt to modify hook: $CMD"
    echo "🛑 PREFECT BLOCK: Cannot modify hook scripts via bash." >&2
    exit 1
  fi
fi

# ── RULE 4: BLOCK SETTINGS.JSON MODIFICATION ──────────
if echo "$CMD" | grep -qE "settings\.json" ; then
  if echo "$CMD" | grep -qE "(>|>>|tee|sed\s+-i|mv\s|cp\s|rm\s)" ; then
    log_audit "BLOCK" "Bash attempt to modify settings.json: $CMD"
    echo "🛑 PREFECT BLOCK: Cannot modify .claude/settings.json via bash." >&2
    exit 1
  fi
fi

# ── RULE 5: BLOCK FORBIDDEN DIRECTORIES VIA BASH ──────
# Match forbidden directory names with or without slashes
# Patterns: mkdir temp, mkdir -p tmp/, touch temp/file.txt, echo > misc/file
FORBIDDEN_DIRS="\btemp\b|\btmp\b|\bmisc\b|\bstuff\b|\bold\b|\bbackup\b|\bbak\b|\bscratch\b|\bjunk\b|\barchive\b"
if echo "$CMD" | grep -qE "(mkdir|touch|cat\s|echo\s|tee|cp\s|mv\s)" ; then
  if echo "$CMD" | grep -qiE "$FORBIDDEN_DIRS"; then
    log_audit "BLOCK" "Bash create in forbidden directory: $CMD"
    echo "🛑 PREFECT BLOCK: Bash command targets a forbidden directory." >&2
    exit 1
  fi
fi

# ── All checks passed ─────────────────────────────────
exit 0
