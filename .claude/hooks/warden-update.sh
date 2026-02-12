#!/usr/bin/env bash
# warden-update.sh — Update Warden hooks while preserving user files
# Two-tier system: Tier 1 (plugin-owned) gets updated, Tier 2 (user-owned) preserved
set -euo pipefail

HOOKS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"

echo "🔍 Checking for Warden updates..."
echo ""

# Check if we're in a git repo (simplest case)
if [ -d "$HOOKS_DIR/.git" ]; then
  echo "📦 Pulling latest changes from git..."
  cd "$HOOKS_DIR"
  git pull origin main
  echo "✅ Updated successfully"
  exit 0
fi

# Otherwise, manual update instructions
echo "📋 To update Warden manually:"
echo ""
echo "Option 1: Download latest hooks"
echo "  curl -fsSL https://github.com/HawkannG/Claude-Warden/archive/main.tar.gz | \\"
echo "    tar xz --strip-components=3 -C .claude/hooks Claude-Warden-main/.claude/hooks/"
echo ""
echo "Option 2: Clone and copy"
echo "  git clone https://github.com/HawkannG/Claude-Warden /tmp/warden"
echo "  cp /tmp/warden/.claude/hooks/*.sh .claude/hooks/"
echo "  rm -rf /tmp/warden"
echo ""
echo "📌 What gets updated (Tier 1 - plugin-owned):"
echo "  ✅ .claude/hooks/*.sh"
echo "  ✅ lockdown.sh"
echo ""
echo "🔒 What stays yours (Tier 2 - user-owned):"
echo "  🔒 .claude/CLAUDE.md"
echo "  🔒 .claude/rules/*.md"
echo "  🔒 .claude/settings.json"
echo "  🔒 .claude/audit.log"
echo "  🔒 docs/SESSION-LOG.md"
echo "  🔒 warden.config.sh"
echo ""
echo "All user files and logs are preserved during updates."
