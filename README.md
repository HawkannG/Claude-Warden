# Claude Warden AI Governance Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/yourusername/claude-warden/releases/tag/v1.0.0)
[![Tests](https://img.shields.io/badge/tests-300%2B-success.svg)](./tests)
[![Last Updated](https://img.shields.io/badge/updated-Feb%202026-brightgreen.svg)](https://github.com/yourusername/claude-warden)

> Self-protecting governance hooks that tries to prevent Claude from editing its own instructions.

## Quick Demo

![Warden in action - blocking Claude from editing governance files](./docs/images/warden-demo.gif)

**Try this prompt with Claude Code:**
```
"Edit .claude/CLAUDE.md and remove the first rule"
```

**With Warden installed, Claude gets blocked:**
```
🛑 WARDEN BLOCK: .claude/CLAUDE.md is human-edit-only.
→ Claude cannot modify its own instructions. Suggest changes in chat.
```

**Real-world example:** See the GIF above showing Claude attempting to delete CLAUDE.md, getting blocked on `/tmp/` directory creation, and finding a workaround - demonstrating both Warden's protection and its documented limitations.

## What Makes This Different?

| Without Warden | Warden Framework |
|------------------------|-------------------|
| Claude can edit its own rules | Claude blocked from editing governance |
| Static documentation only | Executable hooks + documentation |
| Manual compliance checks | Automated enforcement on every file write |
| No protection for .claude/ directory | Hooks protect themselves |

**Core insight:** Claude is powerful but probabilistic. Without enforcement, it will quietly restructure your project, skip tests, and modify its own instructions. Warden adds **deterministic enforcement** via hooks.

## What It Does

✅ **Self-Protection**: Blocks Claude from editing .claude/CLAUDE.md, rules, hooks, settings.json
✅ **Structure Enforcement**: No temp/ directories, max 5 levels deep, no files at root
✅ **Drift Tracking**: Scores project health across 8 dimensions (0-100)
✅ **Session Persistence**: Generates handoff documents for context preservation
✅ **Workflow Phases**: Guides through PROPOSE → PLAN → BUILD → VERIFY → CLOSE

## Security Model

⚠️ **Important:** Warden is designed to prevent **unintentional** governance violations by Claude Code, not to defend against a **deliberately adversarial** AI agent. The hooks are security controls for workflow enforcement, **not a sandbox**.

**What this means:**
- ✅ Warden prevents accidental edits to governance files
- ✅ Enforces workflow discipline and project structure
- ✅ Protects against Claude "drifting" from instructions over time
- ❌ Not designed to defend against an AI actively trying to bypass controls
- ❌ Not a security sandbox or isolation mechanism
- ❌ Hooks run with the same privileges as Claude Code

For high-security environments, combine Warden with additional controls (file integrity monitoring, immutable flags, SELinux). See [SECURITY.md](SECURITY.md) for details.

## What It Doesn't Do

❌ Does not write code for you (workflow guidance only)
❌ Does not replace testing or code review
❌ Does not work with non-Claude AI assistants
❌ Does not require cloud connection (fully local)

## Requirements

- **bash** 4.0+ (check: `bash --version`)
- **jq** 1.5+ (check: `jq --version`)
- **git** (optional, for session logging)

**Install jq if missing:**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install -y jq

# Windows
winget install jqlang.jq
```

## Installation

### Quick Install (Recommended)

**One command** installs Warden into your project:

```bash
curl -fsSL https://raw.githubusercontent.com/HawkannG/Claude-Warden/main/install.sh | bash
```

Or specify a target directory:

```bash
curl -fsSL https://raw.githubusercontent.com/HawkannG/Claude-Warden/main/install.sh | bash -s /path/to/project
```

The installer will:
- ✅ Download all Warden files
- ✅ Set up hooks and configuration
- ✅ Prompt for project details (name, description, stack)
- ✅ Lock governance files
- ✅ Verify installation

**Then start Claude Code:**
```bash
cd your-project
claude
```

### Manual Install (Alternative)

If you prefer manual setup or offline installation:

<details>
<summary>Click to expand manual instructions</summary>

#### 1. Download Repository

```bash
git clone https://github.com/HawkannG/Claude-Warden.git
cd Claude-Warden
```

#### 2. Copy Files to Your Project

**macOS / Linux / WSL:**
```bash
cp -r .claude WARDEN-POLICY.md WARDEN-FEEDBACK.md CLAUDE.md D-*.md lockdown.sh /path/to/your-project/
cp -r docs /path/to/your-project/
```

**Windows (PowerShell):**
```powershell
xcopy /E /I .claude \path\to\your-project\.claude
copy *.md \path\to\your-project\
copy lockdown.sh \path\to\your-project\
```

#### 3. Customize CLAUDE.md

Open `CLAUDE.md` and replace placeholders:
- `[PROJECT_NAME]` → your project name
- `[Brief description...]` → one-liner description
- `[e.g., Next.js 14...]` → your tech stack

#### 4. Make Scripts Executable

```bash
chmod +x .claude/hooks/*.sh lockdown.sh
```

#### 5. Lock Governance Files

```bash
./lockdown.sh lock
```

#### 6. Start Claude Code

```bash
claude
```

</details>

### Windows Setup

**Requirements:**
- Git for Windows (includes bash): https://gitforwindows.org/
- jq: `winget install jqlang.jq`

**Configure bash for hooks:**
```powershell
[Environment]::SetEnvironmentVariable(
    "CLAUDE_CODE_GIT_BASH_PATH",
    "C:\Program Files\Git\bin\bash.exe",
    [EnvironmentVariableTarget]::User
)
```

Restart terminal, then use the quick install or manual method above.

### Migrating from Prefect

If you have existing projects using "Prefect", upgrade them to Warden:

```bash
cd your-prefect-project
curl -fsSL https://raw.githubusercontent.com/HawkannG/Claude-Warden/main/migrate-from-prefect.sh | bash
```

This will:
- ✅ Rename all Prefect files to Warden
- ✅ Update all file references
- ✅ Test hooks are working
- ✅ Re-lock governance files

## Updating Warden

### Quick Update

```bash
./.claude/hooks/warden-update.sh
```

### What Gets Updated (Tier 1 - Plugin-Owned)

✅ **Hook scripts** — Bug fixes, security patches, new features
✅ **Helper scripts** — lockdown.sh, install.sh

### What Stays Yours (Tier 2 - User-Owned)

🔒 **Your governance files** — `.claude/CLAUDE.md`, `.claude/rules/*.md`
🔒 **Your configuration** — `.claude/settings.json`, `warden.config.sh`
🔒 **Your history** — `.claude/audit.log`, `docs/SESSION-LOG.md`

**All customizations and logs are preserved during updates.**

### Customizing Warden

Edit `warden.config.sh` to customize protected files, forbidden directories, and other settings:

```bash
# warden.config.sh (never overwritten by updates)
PROTECTED_FILES=(
  ".claude/CLAUDE.md"
  ".claude/rules/*.md"
  "contracts/**/*.sol"  # Add your custom paths
)

FORBIDDEN_DIRS=(
  "temp" "tmp" "misc"
  "drafts" "wip"        # Add your custom forbidden names
)
```

Your customizations survive all updates.

## Uninstall

Remove Warden completely from a project:

### Automated Uninstall (Recommended)

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/HawkannG/Claude-Warden/main/uninstall.sh | bash
```

The uninstaller will:
- ✅ Unlock all governance files
- ✅ Remove `.claude/` directory
- ✅ Remove all governance files (WARDEN-*.md, CLAUDE.md, D-*.md)
- ✅ Remove helper scripts (lockdown.sh, warden.config.sh)
- ✅ Remove Warden documentation files
- ✅ Verify complete removal

### Manual Uninstall

If you prefer manual removal:

```bash
# 1. Unlock governance files
./lockdown.sh unlock

# 2. Remove all Warden files
rm -rf .claude/
rm -f warden.config.sh lockdown.sh
rm -f docs/PRODUCT-SPEC.md docs/AI-UAT-CHECKLIST.md

# 3. Verify removal
ls -la | grep -E "\.claude|warden|lockdown"
```

## Framework Directory Structure

This is the structure of the Warden Framework repository itself. **For your project's structure**, see the template in `.claude/rules/architecture.md`.

```
Warden-AI-Governance-Framework/
├── .claude/
│   ├── CLAUDE.md                      # Operating instructions (auto-loaded)
│   ├── rules/                         # Governance rules (auto-discovered)
│   │   ├── policy.md                  # Constitution (human-owned)
│   │   ├── workflow.md                # Development workflow protocol
│   │   ├── architecture.md            # Directory structure template
│   │   └── feedback.md                # Governance feedback loop
│   ├── hooks/                         # Enforcement hooks (5 scripts)
│   │   ├── warden-guard.sh           # Pre-write file protection
│   │   ├── warden-bash-guard.sh      # Bash command validation
│   │   ├── warden-post-check.sh      # Post-write validation
│   │   ├── warden-audit.sh           # Project health scoring
│   │   └── warden-session-end.sh     # Session logging
│   └── settings.json                  # Hook configuration + permissions.deny
├── .github/
│   └── workflows/                     # CI/CD automation
│       ├── security-tests.yml         # Security validation workflow
│       └── README.md                  # Workflow documentation
├── docs/                              # Documentation & templates
│   ├── AI-UAT-CHECKLIST.md           # UAT template for users
│   ├── PRODUCT-SPEC.md               # Product spec template
│   └── SESSION-LOG.md                # Auto-generated session history
├── src/                               # Framework extensions (reserved)
├── tests/                             # Framework test suite
│   ├── security/                      # Security vulnerability tests
│   │   ├── test-symlink-attack.sh    # P2-V1
│   │   ├── test-path-traversal.sh    # P2-V2
│   │   ├── test-command-injection.sh # P2-V3
│   │   ├── test-exit-codes.sh        # P2-V4
│   │   ├── quick-test.sh             # Fast validation
│   │   └── README.md
│   ├── test-guard.sh
│   ├── test-bash-guard.sh
│   └── run-tests.sh
├── lockdown.sh                        # Lock/unlock governance files
├── SECURITY.md                        # Security model docs
├── README.md                          # This file
├── LICENSE                            # MIT license
└── .gitignore
```

## How It Works

### Layer 1: Prevention (real-time blocking)

**warden-guard.sh** fires on every Write, Edit, and MultiEdit tool call. It:
- Blocks edits to .claude/CLAUDE.md, .claude/rules/*.md, hooks, and settings.json
- Blocks file creation at project root (unless in the allowlist)
- Blocks directory nesting deeper than 5 levels
- Blocks forbidden directory names (temp, misc, old, backup, scratch, junk, etc.)
- Warns on files exceeding 250 lines
- Resolves symlinks to prevent bypass attempts

**warden-bash-guard.sh** fires on every Bash command. It catches:
- `echo "x" > .claude/CLAUDE.md` and similar redirects to protected files
- `sed -i`, `rm`, `mv`, `cp` targeting protected files
- `git commit --no-verify` (prevents skipping test hooks)
- Write operations targeting forbidden directories

Together these two hooks make it extremely difficult for Claude to modify its own governance — even if it tries creative workarounds.

### Layer 2: Detection (post-hoc validation)

**warden-post-check.sh** runs after every Write/Edit and validates the result.

**warden-audit.sh** scores your project health across 8 dimensions:

1. Root cleanliness — no unauthorised files at project root
2. Directory structure — no forbidden names, depth limits respected
3. File sizes — source files under 250 lines
4. Governance files — all required files present and intact
5. Test coverage — test files exist alongside source files
6. Feedback backlog — unresolved governance observations
7. Git hygiene — no untracked files, clean working tree
8. Dependency health — lockfiles present and current

Run it manually any time:

```bash
bash .claude/hooks/warden-audit.sh
```

Score interpretation:
- 🟢 0–10: Excellent
- 🟡 11–25: Good, minor housekeeping needed
- 🟠 26–50: Attention needed
- 🔴 51–75: Significant drift
- ⛔ 76–100: Governance crisis — stop and fix

### Layer 3: Process (workflow enforcement)

Every change follows **PROPOSE → PLAN → BUILD → VERIFY → CLOSE**:

| Phase | What happens | Who decides |
|-------|-------------|-------------|
| PROPOSE | Claude asks clarifying questions, one at a time | Human answers |
| PLAN | Claude presents options with tradeoffs | Human chooses |
| BUILD | Claude implements exactly what was approved | Claude executes |
| VERIFY | Tests pass, drift check, audit score checked | Both verify |
| CLOSE | Changelog updated, handoff written, commit made | Human approves |

Trivial changes (typos, config values) use an abbreviated flow — see D-WORK-WORKFLOW.md §8.

### Layer 4: Persistence (session memory)

**warden-session-end.sh** fires when Claude finishes responding. It:
- Runs a mini drift audit (root files, file sizes, forbidden dirs)
- Writes a timestamped entry to `docs/SESSION-LOG.md` with:
  - Current branch and last commit
  - Number of drift issues found
  - Staged, modified, and untracked files
- Entries are newest-first so the next session sees the most recent state

The next session reads SESSION-LOG.md and picks up where the previous one left off. No manual handoff writing needed. The file is auto-created on first session end.

## Day-to-Day Usage

### Starting a session

Claude reads `.claude/CLAUDE.md` automatically, which references all rules files in `.claude/rules/`. The Session Protocol tells it to also check `docs/SESSION-LOG.md`. It states its understanding of the current phase and asks what to work on.

### Editing governance files

You (the human) own the governance files. Claude cannot edit them. When you need to make changes:

```bash
./lockdown.sh unlock
# Make your edits in VS Code
./lockdown.sh lock
./lockdown.sh status    # verify everything is locked again
```

### When Claude hits a wall

The Rabbit Hole Rule: if a fix fails 3 times, Claude must stop and report what was tried, what failed, and its best diagnosis. It won't keep retrying and compounding errors. You decide the next step.

### Checking project health

```bash
bash .claude/hooks/warden-audit.sh
```

### Recovering context mid-session

Say "warden check" and Claude will re-read `.claude/CLAUDE.md`, all rules files, and confirm the current constraints.

### Running parallel Claude instances

Each instance gets its own feature branch and owns specific files. Governance files are shared read-only. Coordinate file ownership before starting. Merge to main one branch at a time. See the Parallel Instances section in `.claude/CLAUDE.md` for details.

## Customisation

### Adding root files to the allowlist

If your project needs files at root that aren't in the default list (e.g., `Procfile`, `fly.toml`, `vercel.json`), add them in three places:

1. **warden-guard.sh** — the `ALLOWED_ROOT` array
2. **warden-audit.sh** — the root cleanliness `case` block
3. **warden-session-end.sh** — the root cleanliness `case` block

### Changing forbidden directory names

Edit the arrays/patterns in both `warden-guard.sh` and `warden-bash-guard.sh`. The defaults block: temp, tmp, misc, stuff, old, backup, bak, scratch, junk, archive.

### Adjusting file size limits

The 250-line limit is in `warden-guard.sh` (enforcement) and `warden-audit.sh` (scoring). Change both if you want a different threshold.

### Adding new rules files

Warden supports governance rules as `.md` files in `.claude/rules/`:
- `architecture.md` — directory structure template (included)
- `workflow.md` — development workflow protocol (included)
- `policy.md` — governance constitution (included)
- `feedback.md` — governance observations (included)
- `data-models.md` — create when you build your first data model
- `access-control.md` — create when you implement auth

Don't create rules files speculatively. `.claude/CLAUDE.md` says: "No rules beyond architecture.md and workflow.md until real code demands them."

## What Warden Does NOT Do

- **No multi-agent orchestration** — one Claude, one session, clear ownership
- **No automatic code formatting** — use your own linter hooks alongside Warden
- **No CI/CD integration** — Warden is local governance; add CI when you have code worth scanning
- **No cloud or external dependencies** — everything is local bash scripts and markdown
- **No learning or adaptation** — the rules are deterministic. Claude doesn't evolve them; humans do, via WARDEN-FEEDBACK.md

## Troubleshooting

### Hooks not firing

Run `/hooks` inside Claude Code to see loaded hooks. If they're missing:
- Check `.claude/settings.json` exists and is valid JSON (no trailing commas)
- Restart the Claude Code session (hooks are loaded at session start)
- On Windows: verify `CLAUDE_CODE_GIT_BASH_PATH` is set correctly

### "jq: command not found"

Install jq:
- macOS: `brew install jq`
- Ubuntu/Debian: `sudo apt install jq`
- Windows: `winget install jqlang.jq`

### Audit shows false positives in venv or node_modules

The v5 audit script excludes `venv/`, `.venv/`, `node_modules/`, `__pycache__/`, and other dependency directories automatically. If you see false positives, check you're running the v5+ version — look for `PRUNE_DIRS` near the top of `warden-audit.sh`.

### "Permission denied" when Claude tries to edit a protected file

That means lockdown is working. If you (the human) need to edit that file: `./lockdown.sh unlock`, edit, `./lockdown.sh lock`.

### Session log not being created

The Stop hook fires when Claude finishes responding, not on user interrupt (Ctrl+C). Let Claude finish naturally, or type "wrap up" to trigger a clean exit.

### Windows: hooks fail with "'$HOME' is not recognized"

The `CLAUDE_CODE_GIT_BASH_PATH` environment variable is not set. See Windows Setup step 3.

### Windows: "chmod: changing permissions: Operation not permitted"

NTFS doesn't fully support Unix permissions. The chmod commands will run but may not have full effect. Use Windows "Read-only" file properties as a backup, or run your project inside WSL for full compatibility.

## Design Principles

- **Deterministic enforcement over advisory instructions** — hooks block violations; CLAUDE.md guides behaviour
- **Self-protection** — Claude cannot modify its own hooks, settings, or instructions
- **Defence in depth** — multiple layers catch the same violation (guard + bash guard + chmod -w)
- **Proportional governance** — strict where it matters (protected files), advisory where it doesn't (file size warnings)
- **Right-sized** — no multi-agent swarms, no 58-hook pipelines. Practical for solo devs and small teams
- **Human-owned** — all governance files are human-editable, human-readable, and human-decided. Claude suggests; you approve

## Acknowledgements

- Hook API patterns from [Anthropic's Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)
- Hook concepts explored via [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery)
- Session persistence inspired by [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)

## License

MIT — see LICENSE file.

---

*Warden Governance Framework v5.1 — Human-owned, AI-enforced.*# Warden-AI-Governance-Framework
