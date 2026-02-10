#!/usr/bin/env bash
set -euo pipefail
# prefect-guard.sh — PreToolUse hook for Prefect governance enforcement
# Blocks file operations that violate PREFECT-POLICY.md rules
# Exit 0 = allow, Exit 2 = block (with reason on stderr)

AUDIT_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/audit.log"
log_audit() {
  local level="$1" msg="$2"
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') [$level] $msg" >> "$AUDIT_LOG" 2>/dev/null || true
}

INPUT=$(cat)

# Extract file path — fallback to grep if jq unavailable
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")
else
  FILE_PATH=$(echo "$INPUT" | grep -oP '"(?:file_path|path)"\s*:\s*"\K[^"]+' | head -1 || echo "")
fi

# No file path = not a file operation we care about
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ── PATH TRAVERSAL PROTECTION ──────────────────────────
if echo "$FILE_PATH" | grep -qE '\.\.(/|$)'; then
  log_audit "BLOCK" "Path traversal attempt: $FILE_PATH"
  echo "🛑 PREFECT BLOCK: Path traversal detected in '$FILE_PATH'." >&2
  exit 2
fi

# Resolve paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
REL_PATH="${FILE_PATH#$PROJECT_DIR/}"
FILENAME=$(basename "$REL_PATH")
DIRNAME=$(dirname "$REL_PATH")

# ── SYMLINK RESOLUTION ─────────────────────────────────
if [ -L "$FILE_PATH" ]; then
  REAL_PATH=$(readlink -f "$FILE_PATH")
  log_audit "SYMLINK" "Symlink detected: $FILE_PATH -> $REAL_PATH"
  FILE_PATH="$REAL_PATH"
  REL_PATH="${FILE_PATH#$PROJECT_DIR/}"
  FILENAME=$(basename "$REL_PATH")
  DIRNAME=$(dirname "$REL_PATH")
fi

# ══════════════════════════════════════════════════════
# SELF-PROTECTION — Claude cannot modify its own enforcement
# These rules MUST come first. No exceptions. No workarounds.
# ══════════════════════════════════════════════════════

# ── RULE 0a: HOOK SCRIPTS are HUMAN-ONLY ──────────────
if echo "$REL_PATH" | grep -qE '^\.claude/hooks/'; then
  log_audit "BLOCK" "Attempted edit of hook script: $REL_PATH"
  echo "🛑 PREFECT BLOCK: Hook scripts (.claude/hooks/) are human-edit-only." >&2
  echo "   → Claude cannot modify its own enforcement. Suggest changes in chat." >&2
  exit 2
fi

# ── RULE 0b: SETTINGS.JSON is HUMAN-ONLY ──────────────
if echo "$REL_PATH" | grep -qE '^\.claude/settings\.json$'; then
  log_audit "BLOCK" "Attempted edit of settings.json: $REL_PATH"
  echo "🛑 PREFECT BLOCK: .claude/settings.json is human-edit-only." >&2
  echo "   → Claude cannot modify hook configuration. Suggest changes in chat." >&2
  exit 2
fi

# ── RULE 0c: CLAUDE.MD is HUMAN-ONLY ──────────────────
if [ "$FILENAME" = "CLAUDE.md" ]; then
  log_audit "BLOCK" "Attempted edit of CLAUDE.md"
  echo "🛑 PREFECT BLOCK: CLAUDE.md is human-edit-only." >&2
  echo "   → Claude cannot modify its own instructions. Suggest changes in chat." >&2
  exit 2
fi

# ── RULE 0d: PREFECT-POLICY.md is HUMAN-ONLY ─────────
if [ "$FILENAME" = "PREFECT-POLICY.md" ]; then
  log_audit "BLOCK" "Attempted edit of PREFECT-POLICY.md"
  echo "🛑 PREFECT BLOCK: PREFECT-POLICY.md is human-edit-only (Policy §2.1)." >&2
  echo "   → Suggest your changes in chat. The human will edit this file." >&2
  exit 2
fi

# ══════════════════════════════════════════════════════
# STRUCTURAL RULES — File placement and organization
# ══════════════════════════════════════════════════════

# ── RULE 1: ROOT LOCKDOWN ─────────────────────────────
if [ "$DIRNAME" = "." ] || [ "$DIRNAME" = "$PROJECT_DIR" ]; then
  ALLOWED_ROOT=(
    "PREFECT-POLICY.md" "CLAUDE.md" "PREFECT-FEEDBACK.md"
    "README.md" "LICENSE" "LICENSE.md"
    "package.json" "package-lock.json" "pnpm-lock.yaml" "yarn.lock"
    "tsconfig.json" "requirements.txt" "pyproject.toml"
    "setup.py" "setup.cfg" "Makefile" "Dockerfile"
    "docker-compose.yml" "docker-compose.yaml"
    ".gitignore" ".env" ".env.example" ".editorconfig" ".nvmrc"
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
    "lockdown.sh"
  )

  # Allow D-*.md directive files
  if [[ "$FILENAME" =~ ^D-[A-Z]+-[A-Z]+\.md$ ]]; then
    exit 0
  fi

  ALLOWED=false
  for f in "${ALLOWED_ROOT[@]}"; do
    if [ "$FILENAME" = "$f" ]; then
      ALLOWED=true
      break
    fi
  done

  if [ "$ALLOWED" = false ]; then
    log_audit "BLOCK" "Unauthorized root file: $FILENAME"
    echo "🛑 PREFECT BLOCK: '$FILENAME' is not a registered root file (Policy §3.1)." >&2
    echo "   → Root directory is locked. Add to ALLOWED_ROOT in prefect-guard.sh if needed." >&2
    exit 2
  fi
fi

# ── RULE 2: DIRECTORY DEPTH LIMIT (max 5 levels) ──────
DEPTH=$(echo "$REL_PATH" | tr '/' '\n' | wc -l)
if [ "$DEPTH" -gt 6 ]; then
  log_audit "BLOCK" "Directory depth exceeded: $REL_PATH (depth $DEPTH)"
  echo "🛑 PREFECT BLOCK: '$REL_PATH' exceeds max depth of 5 (Policy §3.2)." >&2
  exit 2
fi

# ── RULE 3: FORBIDDEN DIRECTORY NAMES ─────────────────
FORBIDDEN_DIRS=("temp" "tmp" "misc" "stuff" "old" "backup" "bak" "scratch" "junk" "archive")
for dir in $(echo "$REL_PATH" | tr '/' '\n'); do
  dir_lower=$(echo "$dir" | tr '[:upper:]' '[:lower:]')
  for forbidden in "${FORBIDDEN_DIRS[@]}"; do
    if [ "$dir_lower" = "$forbidden" ]; then
      log_audit "BLOCK" "Forbidden directory: $dir in $REL_PATH"
      echo "🛑 PREFECT BLOCK: Directory name '$dir' is forbidden (Policy §3.2)." >&2
      exit 2
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
      exit 2
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
