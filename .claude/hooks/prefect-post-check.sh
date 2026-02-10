#!/bin/bash
# prefect-post-check.sh — PostToolUse hook for Prefect governance
# Runs AFTER successful file writes. Warns about drift, does not block.
# Output goes to stderr as feedback to Claude.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
REL_PATH="${FILE_PATH#$PROJECT_DIR/}"
FILENAME=$(basename "$REL_PATH")

# ============================================================
# CHECK: Source file exceeded 250-line soft limit after edit
# ============================================================
if [[ "$FILENAME" =~ \.(ts|tsx|js|jsx|py|rb|go|rs|java|cs|cpp|c|h|hpp|swift|kt)$ ]]; then
  if [ -f "$FILE_PATH" ]; then
    LINES=$(wc -l < "$FILE_PATH")
    if [ "$LINES" -gt 250 ]; then
      echo "⚠️  PREFECT DRIFT: '$REL_PATH' is now $LINES lines (limit: 250)." >&2
      echo "   → Log this in PREFECT-FEEDBACK.md and consider splitting." >&2
    fi
  fi
fi

# ============================================================
# CHECK: New file created outside common known directories
# Heuristic — warns if path doesn't match typical project structure
# ============================================================
KNOWN_DIRS="src|lib|app|components|pages|routes|models|services|schemas|hooks|utils|tests|test|spec|scripts|docs|public|static|assets|config|migrations|prisma|drizzle|backend|frontend|api|styles|types|interfaces|middleware|helpers|constants|fixtures|mocks|stubs|__tests__"

FIRST_DIR=$(echo "$REL_PATH" | cut -d'/' -f1)
if [ "$FIRST_DIR" != "$FILENAME" ]; then  # Not a root file
  FIRST_LOWER=$(echo "$FIRST_DIR" | tr '[:upper:]' '[:lower:]')
  if ! echo "$FIRST_LOWER" | grep -qE "^($KNOWN_DIRS)$"; then
    # Check if it starts with a dot (hidden/config dir — allow)
    if [[ ! "$FIRST_DIR" =~ ^\. ]]; then
      echo "📋 PREFECT NOTE: New file in '$FIRST_DIR/' — verify this directory is in your structure policy." >&2
    fi
  fi
fi

# ============================================================
# CHECK: Directive file should have required header fields
# ============================================================
if [[ "$FILENAME" =~ ^D-[A-Z]+-[A-Z]+\.md$ ]]; then
  if [ -f "$FILE_PATH" ]; then
    MISSING=""
    grep -q "^# D-" "$FILE_PATH" || MISSING="${MISSING} title"
    grep -q "Policy Area:" "$FILE_PATH" || MISSING="${MISSING} policy-area"
    grep -q "Version:" "$FILE_PATH" || MISSING="${MISSING} version"
    grep -q "Status:" "$FILE_PATH" || MISSING="${MISSING} status"

    if [ -n "$MISSING" ]; then
      echo "⚠️  PREFECT DRIFT: Directive '$FILENAME' missing required headers:$MISSING" >&2
      echo "   → See PREFECT-POLICY.md §4.2 for required directive format." >&2
    fi
  fi
fi

exit 0
