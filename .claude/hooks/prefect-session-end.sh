#!/usr/bin/env bash
set -euo pipefail  # FIX V8: Exit on error, undefined var, pipe failure
# prefect-session-end.sh — Stop hook for Prefect governance
# Runs when Claude Code session ends. Performs mini drift audit.
# Output is informational — reminds Claude to do session-end protocol.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Verify PROJECT_DIR exists (handle gracefully - session-end is informational)
if [ ! -d "$PROJECT_DIR" ]; then
  echo "⚠️  PROJECT_DIR not found: $PROJECT_DIR" >&2
  echo "   Session-end audit skipped." >&2
  exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "📋 PREFECT SESSION-END AUDIT" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

ISSUES=0

# Check: Are there unauthorized root files?
ROOT_UNKNOWN=()
for f in "$PROJECT_DIR"/*; do
  [ ! -f "$f" ] && continue
  fname=$(basename "$f")
  case "$fname" in
    PREFECT-POLICY.md|CLAUDE.md|PREFECT-FEEDBACK.md|README.md|SECURITY.md|LICENSE*) ;;
    lockdown.sh) ;;
    D-*.md) ;;
    package.json|package-lock.json|tsconfig.json|requirements.txt|pyproject.toml) ;;
    setup.py|setup.cfg|Makefile|Dockerfile|docker-compose.*) ;;
    .gitignore|.env.example|.eslintrc*|.prettierrc*|.folderslintrc|.lslintrc.yml) ;;
    vite.config.*|next.config.*|tailwind.config.*|postcss.config.*) ;;
    jest.config.*|vitest.config.*|playwright.config.*) ;;
    *)
      ROOT_UNKNOWN+=("$fname")
      ;;
  esac
done

if [ ${#ROOT_UNKNOWN[@]} -gt 0 ]; then
  ISSUES=$((ISSUES + 1))
  echo "⚠️  Unregistered root files: ${ROOT_UNKNOWN[*]}" >&2
fi

# Check: Does PREFECT-FEEDBACK.md exist?
if [ ! -f "$PROJECT_DIR/PREFECT-FEEDBACK.md" ]; then
  echo "📝 No PREFECT-FEEDBACK.md found (create if you have governance observations)." >&2
fi

# Check: How many directives exist?
DIRECTIVE_COUNT=$(find "$PROJECT_DIR" -maxdepth 1 -name "D-*.md" 2>/dev/null | wc -l)
echo "📊 Active directives: $DIRECTIVE_COUNT" >&2

# Check: Any source files over 250 lines?
BIG_FILES=0
if [ -d "$PROJECT_DIR/src" ]; then
  BIG_FILES=$(find "$PROJECT_DIR/src" -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" 2>/dev/null | while read f; do
    lines=$(wc -l < "$f")
    [ "$lines" -gt 250 ] && echo "$f"
  done | wc -l)
fi
if [ -d "$PROJECT_DIR/backend" ]; then
  BIG_FILES=$((BIG_FILES + $(find "$PROJECT_DIR/backend" -name "*.py" 2>/dev/null | while read f; do
    lines=$(wc -l < "$f")
    [ "$lines" -gt 250 ] && echo "$f"
  done | wc -l)))
fi
if [ "$BIG_FILES" -gt 0 ]; then
  ISSUES=$((ISSUES + 1))
  echo "⚠️  Files exceeding 250-line limit: $BIG_FILES" >&2
fi

# Check: Any forbidden directory names?
FORBIDDEN=$(find "$PROJECT_DIR" -type d \( -iname "temp" -o -iname "tmp" -o -iname "misc" -o -iname "stuff" -o -iname "old" -o -iname "backup" -o -iname "bak" -o -iname "scratch" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l)
if [ "$FORBIDDEN" -gt 0 ]; then
  ISSUES=$((ISSUES + 1))
  echo "⚠️  Forbidden directory names found: $FORBIDDEN" >&2
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
if [ "$ISSUES" -eq 0 ]; then
  echo "✅ No drift detected. Clean session." >&2
else
  echo "⚠️  $ISSUES drift issue(s) detected. Log in PREFECT-FEEDBACK.md." >&2
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

exit 0
