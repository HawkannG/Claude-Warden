#!/usr/bin/env bash
set -euo pipefail
# warden-guard.sh — PreToolUse hook for Warden governance enforcement
# Blocks file operations that violate WARDEN-POLICY.md rules
# Exit 0 = allow, Exit 1 = block (with reason on stderr), Exit 2 = error

# ── LOAD USER CONFIGURATION (Tier 2 - never overwritten) ──
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"
if [ -f "$PROJECT_ROOT/warden.config.sh" ]; then
  # SECURITY: Sourcing user-editable code is risky, but necessary for config flexibility.
  # warden.config.sh is protected in PROTECTED_FILES and has a hardcoded check below.
  source "$PROJECT_ROOT/warden.config.sh"
else
  # Defaults (when no config file exists)
  PROTECTED_FILES=(
    ".claude/CLAUDE.md"
    ".claude/rules/*.md"
    ".claude/hooks/*.sh"
    ".claude/settings.json"
    "lockdown.sh"
    "warden.config.sh"
  )
  FORBIDDEN_DIRS=(
    "temp" "tmp" "misc" "stuff" "old"
    "backup" "bak" "scratch" "junk" "archive"
  )
  MAX_DIRECTORY_DEPTH=5
  AUDIT_LOG_PATH=".claude/audit.log"
  EXIT_ALLOW=0
  EXIT_BLOCK=1
  EXIT_ERROR=2
fi

AUDIT_LOG="$PROJECT_ROOT/${AUDIT_LOG_PATH:-.claude/audit.log}"
log_audit() {
  local level="$1" msg="$2"
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') [$level] $msg" >> "$AUDIT_LOG" 2>/dev/null || true
}

INPUT=$(cat)

# Extract file path — jq is required (FIX V5: No unsafe grep fallback)
if ! command -v jq &>/dev/null; then
  echo "🛑 WARDEN ERROR: jq is required for hook operation" >&2
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

# ── CROSS-PLATFORM PATH RESOLUTION HELPER ────────────
# Works on Linux, macOS, and WSL
resolve_path() {
  local path="$1"
  local resolved=""

  # Try realpath first (Linux, Homebrew on macOS)
  if command -v realpath &>/dev/null; then
    resolved=$(realpath -m "$path" 2>/dev/null)
    if [ -n "$resolved" ]; then
      echo "$resolved"
      return 0
    fi
  fi

  # Fallback for macOS: use Python3 (installed by default on macOS)
  # FIX: Pass path as argv to prevent injection attacks
  if command -v python3 &>/dev/null; then
    resolved=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$path" 2>/dev/null)
    if [ -n "$resolved" ]; then
      echo "$resolved"
      return 0
    fi
  fi

  # Last resort: readlink -f (Linux only, fails on macOS)
  resolved=$(readlink -f "$path" 2>/dev/null)
  if [ -n "$resolved" ]; then
    echo "$resolved"
    return 0
  fi

  # If all methods fail, return empty
  return 1
}

# ── FIX V1: SYMLINK ATTACK PROTECTION ─────────────────
# Resolve symlinks to real path before any checks
if [ -L "$FILE_PATH" ]; then
  REAL_PATH=$(resolve_path "$FILE_PATH")
  if [ -n "$REAL_PATH" ]; then
    FILE_PATH="$REAL_PATH"
    log_audit "SYMLINK" "Resolved symlink: $FILE_PATH"
  fi
fi

# ── FIX V2: PATH TRAVERSAL PROTECTION ─────────────────
# Resolve to canonical path (handles encoded .., symlinks, relative paths)
CANONICAL_PATH=$(resolve_path "$FILE_PATH")
if [ -z "$CANONICAL_PATH" ]; then
  log_audit "BLOCK" "Failed to resolve canonical path: $FILE_PATH"
  echo "🛑 WARDEN BLOCK: Invalid file path '$FILE_PATH'." >&2
  echo "   → Install realpath (Linux: coreutils, macOS: brew install coreutils)" >&2
  echo "   → Or ensure python3 is available (default on macOS)" >&2
  exit 1
fi

# Verify canonical path is inside PROJECT_DIR
# FIX: Add trailing slash to prevent sibling directory bypass (project-secrets/ vs project/)
case "$CANONICAL_PATH" in
  "$CANONICAL_PROJECT"/*)
    # Path is inside project, OK
    ;;
  *)
    log_audit "BLOCK" "Path outside project: $CANONICAL_PATH"
    echo "🛑 WARDEN BLOCK: File '$FILE_PATH' is outside project directory." >&2
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

# ── RULE 0: HARDCODED PROTECTION (Defense-in-Depth) ──────
# These checks run BEFORE config-driven checks as a safety net
# in case someone empties warden.config.sh or it's misconfigured.

# RULE 0a: warden.config.sh itself (CRITICAL - prevents arbitrary code execution)
if echo "$REL_PATH" | grep -qE '^warden\.config\.sh$'; then
  log_audit "BLOCK" "Attempted edit of warden.config.sh"
  echo "🛑 WARDEN BLOCK: warden.config.sh is human-edit-only." >&2
  echo "   → This file is sourced by hooks. Editing via Claude could execute arbitrary code." >&2
  echo "   → Edit manually with a text editor." >&2
  exit 1
fi

# RULE 0b: Hook scripts (redundant with PROTECTED_FILES but kept as failsafe)
if echo "$REL_PATH" | grep -qE '^\.claude/hooks/.*\.sh$'; then
  log_audit "BLOCK" "Attempted edit of hook script: $REL_PATH"
  echo "🛑 WARDEN BLOCK: Hooks cannot modify themselves." >&2
  exit 1
fi

# RULE 0c: settings.json (redundant with PROTECTED_FILES but kept as failsafe)
if echo "$REL_PATH" | grep -qE '^\.claude/settings\.json$'; then
  log_audit "BLOCK" "Attempted edit of settings.json: $REL_PATH"
  echo "🛑 WARDEN BLOCK: settings.json is managed by Claude Code, not hooks." >&2
  exit 1
fi

# ── RULE 0: PROTECTED FILES (from warden.config.sh) ────────
# Config-driven checks for user-customizable protected file patterns
for pattern in "${PROTECTED_FILES[@]}"; do
  # Convert glob pattern to regex for matching
  # FIX: Escape dots BEFORE converting wildcards (order matters!)
  pattern_regex=$(echo "$pattern" | sed 's/\./\\./g' | sed 's/\*/[^/]*/g')

  if echo "$REL_PATH" | grep -qE "^${pattern_regex}$"; then
    log_audit "BLOCK" "Attempted edit of protected file: $REL_PATH"
    echo "🛑 WARDEN BLOCK: '$REL_PATH' is a protected file (Tier 2 - user-owned)." >&2
    echo "   → This file cannot be modified via Write/Edit tools." >&2
    echo "   → For governance files: Suggest changes in chat. The human will edit." >&2
    echo "   → To customize: Edit warden.config.sh PROTECTED_FILES array." >&2
    exit ${EXIT_BLOCK:-1}
  fi
done

# ══════════════════════════════════════════════════════
# STRUCTURAL RULES — File placement and organization
# ══════════════════════════════════════════════════════

# ── RULE 1: ROOT LOCKDOWN ─────────────────────────────
if [ "$DIRNAME" = "." ] || [ "$DIRNAME" = "$PROJECT_DIR" ]; then
  ALLOWED_ROOT=(
    "README.md" "SECURITY.md" "LICENSE" "LICENSE.md" "CHANGELOG.md"
    "lockdown.sh" "warden.config.sh"
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

  # Check against allowed root files list
  ALLOWED=false
  for f in "${ALLOWED_ROOT[@]}"; do
    if [ "$FILENAME" = "$f" ]; then
      ALLOWED=true
      break
    fi
  done

  if [ "$ALLOWED" = false ]; then
    log_audit "BLOCK" "Unauthorized root file: $FILENAME"
    echo "🛑 WARDEN BLOCK: '$FILENAME' is not a registered root file (Policy §3.1)." >&2
    echo "   → Root directory is locked. Add to ALLOWED_ROOT in warden-guard.sh if needed." >&2
    exit 1
  fi
fi

# ── RULE 2: DIRECTORY DEPTH LIMIT (max 5 levels) ──────
DEPTH=$(echo "$REL_PATH" | tr '/' '\n' | wc -l)
if [ "$DEPTH" -gt 6 ]; then
  log_audit "BLOCK" "Directory depth exceeded: $REL_PATH (depth $DEPTH)"
  echo "🛑 WARDEN BLOCK: '$REL_PATH' exceeds max depth of 5 (Policy §3.2)." >&2
  exit 1
fi

# ── RULE 3: FORBIDDEN DIRECTORY NAMES (from warden.config.sh) ─────────────────
# FORBIDDEN_DIRS loaded from config at top of file (no hardcoded override)
for dir in $(echo "$REL_PATH" | tr '/' '\n'); do
  dir_lower=$(echo "$dir" | tr '[:upper:]' '[:lower:]')
  for forbidden in "${FORBIDDEN_DIRS[@]}"; do
    if [ "$dir_lower" = "$forbidden" ]; then
      log_audit "BLOCK" "Forbidden directory: $dir in $REL_PATH"
      echo "🛑 WARDEN BLOCK: Directory name '$dir' is forbidden (Policy §3.2)." >&2
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
      echo "🛑 WARDEN BLOCK: Directive '$FILENAME' is $LINES lines (max 300)." >&2
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
      echo "⚠️  WARDEN WARNING: '$FILENAME' is $LINES lines (limit 250)." >&2
    fi
  fi
fi

# ── All checks passed ─────────────────────────────────
log_audit "ALLOW" "Write permitted: $REL_PATH"
exit 0
