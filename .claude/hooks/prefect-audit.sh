#!/bin/bash
# prefect-audit.sh — Automated Prefect Drift Score Calculator
# Run: bash .claude/hooks/prefect-audit.sh [project-dir]
# Outputs: Drift score (0-100, lower = healthier) + detailed breakdown
#
# Scoring dimensions (each 0-12.5 points, total max 100):
#   1. Root cleanliness      — unauthorized files at root
#   2. Directory discipline   — forbidden names, excessive depth
#   3. File size compliance   — source files within limits
#   4. Directive health       — format, freshness, count within limits
#   5. Governance coverage    — required files present
#   6. Feedback backlog       — unresolved feedback entries
#   7. Structural orphans     — empty dirs, duplicate-purpose dirs
#   8. Documentation currency — staleness of key governance files

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-.}}"
SCORE=0
TOTAL_POSSIBLE=0
DETAILS=""

# ── GLOBAL EXCLUSIONS ─────────────────────────────────
# Directories that should never be scanned (dependencies, caches, build output)
PRUNE_DIRS="-path */node_modules/* -o -path */.git/* -o -path */.next/* -o -path */dist/* -o -path */build/* -o -path */venv/* -o -path */.venv/* -o -path */__pycache__/* -o -path */.pytest_cache/* -o -path */.mypy_cache/* -o -path */*.egg-info/*"

add_score() {
  local points=$1
  local max=$2
  local reason=$3
  SCORE=$((SCORE + points))
  TOTAL_POSSIBLE=$((TOTAL_POSSIBLE + max))
  if [ "$points" -gt 0 ]; then
    DETAILS="${DETAILS}\n  ⚠️  +${points}/${max}: ${reason}"
  else
    DETAILS="${DETAILS}\n  ✅  0/${max}: ${reason}"
  fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 PREFECT GOVERNANCE AUDIT"
echo "   Project: $(basename "$(cd "$PROJECT_DIR" && pwd)")"
echo "   Date:    $(date '+%Y-%m-%d %H:%M')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── DIMENSION 1: Root Cleanliness ──────────────────────
echo ""
echo "1. ROOT CLEANLINESS"
ROOT_UNKNOWN=0
for f in "$PROJECT_DIR"/*; do
  [ ! -f "$f" ] && continue
  fname=$(basename "$f")
  case "$fname" in
    PREFECT-POLICY.md|CLAUDE.md|PREFECT-FEEDBACK.md|README.md|LICENSE*) ;;
    D-*.md) ;;
    package.json|package-lock.json|pnpm-lock.yaml|yarn.lock) ;;
    tsconfig.json|tsconfig.*.json|requirements.txt|pyproject.toml) ;;
    setup.py|setup.cfg|Makefile|Dockerfile|docker-compose.*) ;;
    .gitignore|.env|.env.example|.eslintrc*|.prettierrc*|biome.json) ;;
    .folderslintrc|.lslintrc.yml|.editorconfig|.nvmrc|.node-version) ;;
    vite.config.*|next.config.*|tailwind.config.*|postcss.config.*) ;;
    jest.config.*|vitest.config.*|playwright.config.*) ;;
    *.config.js|*.config.ts|*.config.mjs) ;;
    lockdown.sh) ;;
    *)
      ROOT_UNKNOWN=$((ROOT_UNKNOWN + 1))
      echo "   ⚠️  Unauthorized: $fname"
      ;;
  esac
done
if [ "$ROOT_UNKNOWN" -eq 0 ]; then
  add_score 0 13 "Root directory clean"
elif [ "$ROOT_UNKNOWN" -le 2 ]; then
  add_score 4 13 "$ROOT_UNKNOWN unauthorized root file(s)"
elif [ "$ROOT_UNKNOWN" -le 5 ]; then
  add_score 8 13 "$ROOT_UNKNOWN unauthorized root files"
else
  add_score 13 13 "$ROOT_UNKNOWN unauthorized root files — root is compromised"
fi

# ── DIMENSION 2: Directory Discipline ──────────────────
echo ""
echo "2. DIRECTORY DISCIPLINE"
FORBIDDEN_DIRS=$(find "$PROJECT_DIR" -type d \( -iname "temp" -o -iname "tmp" -o -iname "misc" -o -iname "stuff" -o -iname "old" -o -iname "backup" -o -iname "bak" -o -iname "scratch" -o -iname "junk" -o -iname "archive" \) -not \( $PRUNE_DIRS \) 2>/dev/null)
FORBIDDEN_COUNT=$(echo "$FORBIDDEN_DIRS" | grep -c . 2>/dev/null || echo 0)
[ -z "$FORBIDDEN_DIRS" ] && FORBIDDEN_COUNT=0

DEEP_FILES=$(find "$PROJECT_DIR" -type f -not \( $PRUNE_DIRS \) 2>/dev/null | while read f; do
  rel="${f#$PROJECT_DIR/}"
  depth=$(echo "$rel" | tr '/' '\n' | wc -l)
  [ "$depth" -gt 6 ] && echo "$rel"
done)
DEEP_COUNT=$(echo "$DEEP_FILES" | grep -c . 2>/dev/null || echo 0)
[ -z "$DEEP_FILES" ] && DEEP_COUNT=0

DIR_ISSUES=$((FORBIDDEN_COUNT + DEEP_COUNT))
if [ "$DIR_ISSUES" -eq 0 ]; then
  add_score 0 12 "No forbidden dirs, no excessive depth"
elif [ "$DIR_ISSUES" -le 3 ]; then
  add_score 4 12 "$DIR_ISSUES directory discipline issue(s)"
else
  add_score 12 12 "$DIR_ISSUES directory discipline issues"
fi

for d in $FORBIDDEN_DIRS; do
  echo "   ⚠️  Forbidden dir: ${d#$PROJECT_DIR/}"
done

# ── DIMENSION 3: File Size Compliance ──────────────────
echo ""
echo "3. FILE SIZE COMPLIANCE"
BIG_FILES=$(find "$PROJECT_DIR" \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) -not \( $PRUNE_DIRS \) -not -name "*.config.*" -not -name "*.d.ts" 2>/dev/null | while read f; do
  lines=$(wc -l < "$f")
  [ "$lines" -gt 250 ] && echo "$lines $f"
done | sort -rn)
BIG_COUNT=$(echo "$BIG_FILES" | grep -c . 2>/dev/null || echo 0)
[ -z "$BIG_FILES" ] && BIG_COUNT=0

TOTAL_SOURCE=$(find "$PROJECT_DIR" \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) -not \( $PRUNE_DIRS \) -not -name "*.config.*" -not -name "*.d.ts" 2>/dev/null | wc -l)

if [ "$BIG_COUNT" -eq 0 ]; then
  add_score 0 13 "All $TOTAL_SOURCE source files within 250-line limit"
elif [ "$TOTAL_SOURCE" -gt 0 ]; then
  PERCENT=$((BIG_COUNT * 100 / TOTAL_SOURCE))
  if [ "$PERCENT" -le 10 ]; then
    add_score 4 13 "$BIG_COUNT/$TOTAL_SOURCE files over limit ($PERCENT%)"
  elif [ "$PERCENT" -le 25 ]; then
    add_score 8 13 "$BIG_COUNT/$TOTAL_SOURCE files over limit ($PERCENT%)"
  else
    add_score 13 13 "$BIG_COUNT/$TOTAL_SOURCE files over limit ($PERCENT%) — widespread"
  fi
  echo "$BIG_FILES" | head -5 | while read line; do
    echo "   ⚠️  $line"
  done
else
  add_score 0 13 "No source files found"
fi

# ── DIMENSION 4: Directive Health ──────────────────────
echo ""
echo "4. DIRECTIVE HEALTH"
DIRECTIVES=$(find "$PROJECT_DIR" -maxdepth 1 -name "D-*.md" 2>/dev/null)
DIR_COUNT=$(echo "$DIRECTIVES" | grep -c . 2>/dev/null || echo 0)
[ -z "$DIRECTIVES" ] && DIR_COUNT=0

DIR_ISSUES=0
if [ "$DIR_COUNT" -gt 28 ]; then
  DIR_ISSUES=$((DIR_ISSUES + 1))
  echo "   ⚠️  Too many directives: $DIR_COUNT (max 28)"
fi

for d in $DIRECTIVES; do
  [ ! -f "$d" ] && continue
  dname=$(basename "$d")
  lines=$(wc -l < "$d")
  if [ "$lines" -gt 300 ]; then
    DIR_ISSUES=$((DIR_ISSUES + 1))
    echo "   ⚠️  $dname: $lines lines (max 300)"
  fi
  if ! grep -q "Policy Area:" "$d" 2>/dev/null; then
    DIR_ISSUES=$((DIR_ISSUES + 1))
    echo "   ⚠️  $dname: missing 'Policy Area:' header"
  fi
  if ! grep -q "Status:" "$d" 2>/dev/null; then
    DIR_ISSUES=$((DIR_ISSUES + 1))
    echo "   ⚠️  $dname: missing 'Status:' header"
  fi
done

if [ "$DIR_ISSUES" -eq 0 ]; then
  add_score 0 12 "$DIR_COUNT directive(s), all healthy"
elif [ "$DIR_ISSUES" -le 2 ]; then
  add_score 4 12 "$DIR_ISSUES directive format issue(s)"
else
  add_score 12 12 "$DIR_ISSUES directive issues — needs cleanup"
fi

# ── DIMENSION 5: Governance Coverage ───────────────────
echo ""
echo "5. GOVERNANCE COVERAGE"
REQUIRED_FILES=("CLAUDE.md" "README.md" "PREFECT-POLICY.md")
MISSING_GOV=0
for rf in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$PROJECT_DIR/$rf" ]; then
    MISSING_GOV=$((MISSING_GOV + 1))
    echo "   ❌ Missing: $rf"
  fi
done

if [ "$MISSING_GOV" -eq 0 ]; then
  add_score 0 13 "All required governance files present"
elif [ "$MISSING_GOV" -eq 1 ]; then
  add_score 5 13 "$MISSING_GOV required governance file missing"
else
  add_score 13 13 "$MISSING_GOV required governance files missing — governance gap"
fi

# ── DIMENSION 6: Feedback Backlog ──────────────────────
echo ""
echo "6. FEEDBACK BACKLOG"
if [ -f "$PROJECT_DIR/PREFECT-FEEDBACK.md" ]; then
  OPEN_FB=$(grep -c "Status: Open" "$PROJECT_DIR/PREFECT-FEEDBACK.md" 2>/dev/null)
  OPEN_FB=$((OPEN_FB + 0))  # Force integer
  if [ "$OPEN_FB" -eq 0 ]; then
    add_score 0 12 "No open feedback items"
  elif [ "$OPEN_FB" -le 5 ]; then
    add_score 3 12 "$OPEN_FB open feedback item(s) — normal"
  elif [ "$OPEN_FB" -le 15 ]; then
    add_score 7 12 "$OPEN_FB open feedback items — accumulating"
  else
    add_score 12 12 "$OPEN_FB open feedback items — systemic gap, needs human review"
  fi
else
  add_score 0 12 "No feedback file (OK if project is new)"
fi

# ── DIMENSION 7: Structural Orphans ───────────────────
echo ""
echo "7. STRUCTURAL ORPHANS"
EMPTY_DIRS=$(find "$PROJECT_DIR" -type d -empty -not \( $PRUNE_DIRS \) 2>/dev/null | wc -l)

DUPES=0
HAS_UTILS=$(find "$PROJECT_DIR" -type d -name "utils" -not \( $PRUNE_DIRS \) 2>/dev/null | wc -l)
HAS_HELPERS=$(find "$PROJECT_DIR" -type d -name "helpers" -not \( $PRUNE_DIRS \) 2>/dev/null | wc -l)
[ "$HAS_UTILS" -gt 0 ] && [ "$HAS_HELPERS" -gt 0 ] && DUPES=$((DUPES + 1)) && echo "   ⚠️  Both utils/ and helpers/ exist — pick one"

HAS_LIB=$(find "$PROJECT_DIR" -type d -name "lib" -not \( $PRUNE_DIRS \) 2>/dev/null | wc -l)
[ "$HAS_UTILS" -gt 0 ] && [ "$HAS_LIB" -gt 0 ] && DUPES=$((DUPES + 1)) && echo "   ⚠️  Both utils/ and lib/ exist — consolidate"

ORPHAN_ISSUES=$((EMPTY_DIRS + DUPES))
if [ "$ORPHAN_ISSUES" -eq 0 ]; then
  add_score 0 12 "No empty dirs or duplicates"
elif [ "$ORPHAN_ISSUES" -le 3 ]; then
  add_score 4 12 "$ORPHAN_ISSUES structural orphan issue(s)"
else
  add_score 12 12 "$ORPHAN_ISSUES structural orphan issues"
fi

# ── DIMENSION 8: Documentation Currency ────────────────
echo ""
echo "8. DOCUMENTATION CURRENCY"
STALE=0
NOW=$(date +%s)
STALE_DAYS=14

for gf in "CLAUDE.md" "README.md"; do
  if [ -f "$PROJECT_DIR/$gf" ]; then
    LAST_MOD=""
    if command -v git &>/dev/null && git -C "$PROJECT_DIR" rev-parse 2>/dev/null; then
      LAST_MOD=$(git -C "$PROJECT_DIR" log -1 --format="%ct" -- "$gf" 2>/dev/null)
    fi
    if [ -z "$LAST_MOD" ]; then
      LAST_MOD=$(stat -c %Y "$PROJECT_DIR/$gf" 2>/dev/null || stat -f %m "$PROJECT_DIR/$gf" 2>/dev/null)
    fi
    if [ -n "$LAST_MOD" ]; then
      AGE_DAYS=$(( (NOW - LAST_MOD) / 86400 ))
      if [ "$AGE_DAYS" -gt "$STALE_DAYS" ]; then
        STALE=$((STALE + 1))
        echo "   ⚠️  $gf last modified $AGE_DAYS days ago"
      fi
    fi
  fi
done

if [ "$STALE" -eq 0 ]; then
  add_score 0 13 "Governance files are current"
elif [ "$STALE" -eq 1 ]; then
  add_score 5 13 "$STALE governance file is stale"
else
  add_score 13 13 "$STALE governance files are stale — documentation rot"
fi

# ── FINAL SCORE ────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TOTAL_POSSIBLE" -gt 0 ]; then
  DRIFT_SCORE=$((SCORE * 100 / TOTAL_POSSIBLE))
else
  DRIFT_SCORE=0
fi

if [ "$DRIFT_SCORE" -le 10 ]; then
  GRADE="🟢 EXCELLENT"
elif [ "$DRIFT_SCORE" -le 25 ]; then
  GRADE="🟡 GOOD"
elif [ "$DRIFT_SCORE" -le 50 ]; then
  GRADE="🟠 ATTENTION NEEDED"
elif [ "$DRIFT_SCORE" -le 75 ]; then
  GRADE="🔴 SIGNIFICANT DRIFT"
else
  GRADE="⛔ GOVERNANCE CRISIS"
fi

echo ""
echo "  DRIFT SCORE: $DRIFT_SCORE / 100  ($GRADE)"
echo ""
echo "  Breakdown:"
echo -e "$DETAILS"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$DRIFT_SCORE" -le 10 ]; then
  echo "  → No action needed. Keep shipping."
elif [ "$DRIFT_SCORE" -le 25 ]; then
  echo "  → Minor cleanup. Address issues during next session."
elif [ "$DRIFT_SCORE" -le 50 ]; then
  echo "  → Schedule a governance session. Fix before adding features."
elif [ "$DRIFT_SCORE" -le 75 ]; then
  echo "  → STOP feature work. Dedicate next session to drift remediation."
else
  echo "  → FREEZE. Full governance audit required before any work continues."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
