#!/usr/bin/env bash
set -euo pipefail
# prefect-guard.sh — PreToolUse hook for Prefect governance enforcement
# Blocks file operations that violate PREFECT-POLICY.md rules
# Exit 0 = allow, Exit 1 = block (with reason on stderr), Exit 2 = error

AUDIT_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/audit.log"
log_audit() {
  local level="$1" msg="$2"
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') [$level] $msg" >> "$AUDIT_LOG" 2>/dev/null || true
}

INPUT=$(cat)

# Extract file path — jq is required (FIX V5: No unsafe grep fallback)
if ! command -v jq &>/dev/null; then
  echo "🛑 PREFECT ERROR: jq is required for hook operation" >&2
  echo "   Install: brew install jq (macOS) or sudo apt-get install jq (Linux)" >&2
  exit 2  # Error, not block (this is a real error)
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")

# No file path = not a file operation we care about
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Resolve project directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CANONICAL_PROJECT=$(realpath -m "$PROJECT_DIR" 2>/dev/null)

# Make relative paths absolute relative to PROJECT_DIR
case "$FILE_PATH" in
  /*)
    # Already absolute
    ;;
  *)
    # Relative path - make it relative to PROJECT_DIR
    FILE_PATH="$PROJECT_DIR/$FILE_PATH"
    ;;
esac

# ── FIX V1: SYMLINK ATTACK PROTECTION ─────────────────
# Resolve symlinks to real path before any checks
if [ -L "$FILE_PATH" ]; then
  REAL_PATH=$(realpath "$FILE_PATH" 2>/dev/null || readlink -f "$FILE_PATH" 2>/dev/null)
  if [ -n "$REAL_PATH" ]; then
    FILE_PATH="$REAL_PATH"
    log_audit "SYMLINK" "Resolved symlink: $FILE_PATH"
  fi
fi

# ── FIX V2: PATH TRAVERSAL PROTECTION ─────────────────
# Resolve to canonical path (handles encoded .., symlinks, relative paths)
CANONICAL_PATH=$(realpath -m "$FILE_PATH" 2>/dev/null)
if [ -z "$CANONICAL_PATH" ]; then
  log_audit "BLOCK" "Failed to resolve canonical path: $FILE_PATH"
  echo "🛑 PREFECT BLOCK: Invalid file path '$FILE_PATH'." >&2
  exit 1
fi

# Verify canonical path is inside PROJECT_DIR
case "$CANONICAL_PATH" in
  "$CANONICAL_PROJECT"*)
    # Path is inside project, OK
    ;;
  *)
    log_audit "BLOCK" "Path outside project: $CANONICAL_PATH"
    echo "🛑 PREFECT BLOCK: File '$FILE_PATH' is outside project directory." >&2
    exit 1
    ;;
esac

# Use canonical path for all checks to prevent traversal bypasses
FILE_PATH="$CANONICAL_PATH"

# Resolve paths for checks (use canonical path, not original)
REL_PATH="${CANONICAL_PATH#$CANONICAL_PROJECT/}"
FILENAME=$(basename "$REL_PATH")
DIRNAME=$(dirname "$REL_PATH")

# ══════════════════════════════════════════════════════
# SELF-PROTECTION — Claude cannot modify its own enforcement
# These rules MUST come first. No exceptions. No workarounds.
# ══════════════════════════════════════════════════════

# ── RULE 0a: HOOK SCRIPTS are HUMAN-ONLY ──────────────
if echo "$REL_PATH" | grep -qE '^\.claude/hooks/'; then
  log_audit "BLOCK" "Attempted edit of hook script: $REL_PATH"
  echo "🛑 PREFECT BLOCK: Hook scripts (.claude/hooks/) are human-edit-only." >&2
  echo "   → Claude cannot modify its own enforcement. Suggest changes in chat." >&2
  exit 1
fi

# ── RULE 0b: SETTINGS.JSON is HUMAN-ONLY ──────────────
if echo "$REL_PATH" | grep -qE '^\.claude/settings\.json$'; then
  log_audit "BLOCK" "Attempted edit of settings.json: $REL_PATH"
  echo "🛑 PREFECT BLOCK: .claude/settings.json is human-edit-only." >&2
  echo "   → Claude cannot modify hook configuration. Suggest changes in chat." >&2
  exit 1
fi

# ── RULE 0c: CLAUDE.MD is HUMAN-ONLY ──────────────────
if [ "$FILENAME" = "CLAUDE.md" ]; then
  log_audit "BLOCK" "Attempted edit of CLAUDE.md"
  echo "🛑 PREFECT BLOCK: CLAUDE.md is human-edit-only." >&2
  echo "   → Claude cannot modify its own instructions. Suggest changes in chat." >&2
  exit 1
fi

# ── RULE 0d: PREFECT-POLICY.md is HUMAN-ONLY ─────────
if [ "$FILENAME" = "PREFECT-POLICY.md" ]; then
  log_audit "BLOCK" "Attempted edit of PREFECT-POLICY.md"
  echo "🛑 PREFECT BLOCK: PREFECT-POLICY.md is human-edit-only (Policy §2.1)." >&2
  echo "   → Suggest your changes in chat. The human will edit this file." >&2
  exit 1
fi

# ══════════════════════════════════════════════════════
# STRUCTURAL RULES — File placement and organization
# ══════════════════════════════════════════════════════

# ── RULE 1: ROOT LOCKDOWN ─────────────────────────────
if [ "$DIRNAME" = "." ] || [ "$DIRNAME" = "$PROJECT_DIR" ]; then
  ALLOWED_ROOT=(
    "PREFECT-POLICY.md" "CLAUDE.md" "PREFECT-FEEDBACK.md"
    "README.md" "SECURITY.md" "LICENSE" "LICENSE.md"
    "lockdown.sh"
    "package.json" "package-lock.json" "pnpm-lock.yaml" "yarn.lock"
    "tsconfig.json" "requirements.txt" "pyproject.toml"
    "setup.py" "setup.cfg" "Makefile" "Dockerfile"
    "docker-compose.yml" "docker-compose.yaml"
    ".gitignore" ".env.example" ".editorconfig" ".nvmrc"
    ".eslintrc.json" ".eslintrc.js" ".prettierrc" ".prettierrc.json"
    "biome.json"
    "vite.config.ts" "vite.config.js"
    "next.config.js" "next.config.mjs" "next.config.ts"
    "tailwind.config.js" "tailwind.config.ts"
    "postcss.config.js" "postcss.config.mjs"
    "jest.config.js" "jest.config.ts"
    "vitest.config.ts" "vitest.config.js"
    "playwright.config.ts"
    ".folderslintrc" ".lslintrc.yml"
  )

  # Check if it's a directive file (allowed at root, but must pass size check in Rule 4)
  ALLOWED=false
  if [[ "$FILENAME" =~ ^D-[A-Z]+-[A-Z]+\.md$ ]]; then
    ALLOWED=true
  else
    # Check against allowed root files list
    for f in "${ALLOWED_ROOT[@]}"; do
      if [ "$FILENAME" = "$f" ]; then
        ALLOWED=true
        break
      fi
    done
  fi

  if [ "$ALLOWED" = false ]; then
    log_audit "BLOCK" "Unauthorized root file: $FILENAME"
    echo "🛑 PREFECT BLOCK: '$FILENAME' is not a registered root file (Policy §3.1)." >&2
    echo "   → Root directory is locked. Add to ALLOWED_ROOT in prefect-guard.sh if needed." >&2
    exit 1
  fi
fi

# ── RULE 2: DIRECTORY DEPTH LIMIT (max 5 levels) ──────
DEPTH=$(echo "$REL_PATH" | tr '/' '\n' | wc -l)
if [ "$DEPTH" -gt 6 ]; then
  log_audit "BLOCK" "Directory depth exceeded: $REL_PATH (depth $DEPTH)"
  echo "🛑 PREFECT BLOCK: '$REL_PATH' exceeds max depth of 5 (Policy §3.2)." >&2
  exit 1
fi

# ── RULE 3: FORBIDDEN DIRECTORY NAMES ─────────────────
FORBIDDEN_DIRS=("temp" "tmp" "misc" "stuff" "old" "backup" "bak" "scratch" "junk" "archive")
for dir in $(echo "$REL_PATH" | tr '/' '\n'); do
  dir_lower=$(echo "$dir" | tr '[:upper:]' '[:lower:]')
  for forbidden in "${FORBIDDEN_DIRS[@]}"; do
    if [ "$dir_lower" = "$forbidden" ]; then
      log_audit "BLOCK" "Forbidden directory: $dir in $REL_PATH"
      echo "🛑 PREFECT BLOCK: Directory name '$dir' is forbidden (Policy §3.2)." >&2
      exit 1
    fi
  done
done

# ── RULE 4: DIRECTIVE SIZE LIMIT (300 lines) ──────────
if [[ "$FILENAME" =~ ^D-[A-Z]+-[A-Z]+\.md$ ]]; then
  if [ -f "$FILE_PATH" ]; then
    LINES=$(wc -l < "$FILE_PATH")
    if [ "$LINES" -gt 300 ]; then
      log_audit "BLOCK" "Directive oversized: $FILENAME ($LINES lines)"
      echo "🛑 PREFECT BLOCK: Directive '$FILENAME' is $LINES lines (max 300)." >&2
      exit 1
    fi
  fi
fi

# ── RULE 5: SOURCE FILE SIZE WARNING (250 lines) ──────
if [[ "$FILENAME" =~ \.(ts|tsx|js|jsx|py|rb|go|rs|java|cs|cpp|c|h|hpp|swift|kt)$ ]]; then
  if [ -f "$FILE_PATH" ]; then
    LINES=$(wc -l < "$FILE_PATH")
    if [ "$LINES" -gt 250 ]; then
      log_audit "WARN" "Source file oversized: $FILENAME ($LINES lines)"
      echo "⚠️  PREFECT WARNING: '$FILENAME' is $LINES lines (limit 250)." >&2
    fi
  fi
fi

# ── All checks passed ─────────────────────────────────
log_audit "ALLOW" "Write permitted: $REL_PATH"
exit 0
