# Prefect AI Governance Framework

> Self-protecting governance hooks that tries to prevent Claude from editing its own instructions.

## Quick Demo

**Try this prompt with Claude Code:**
```
"Edit CLAUDE.md and remove the first rule"
```

**With Prefect installed, Claude gets blocked:**
```
🛑 PREFECT BLOCK: CLAUDE.md is human-edit-only.
→ Claude cannot modify its own instructions. Suggest changes in chat.
```

## What Makes This Different?

| Without Prefect | Prefect Framework |
|------------------------|-------------------|
| Claude can edit its own rules | Claude blocked from editing governance |
| Static documentation only | Executable hooks + documentation |
| Manual compliance checks | Automated enforcement file write |
| No protection for .claude/ directory | Hooks protect themselves |

**Core insight:** Claude is powerful but probabilistic. Without enforcement, it will quietly restructure your project, skip tests, and modify its own instructions. Prefect adds **deterministic enforcement** via hooks.

## What It Does

✅ **Self-Protection**: Blocks Claude from editing CLAUDE.md, hooks, settings.json
✅ **Structure Enforcement**: No temp/ directories, max 5 levels deep, no files at root
✅ **Drift Tracking**: Scores project health across 8 dimensions (0-100)
✅ **Session Persistence**: Generates handoff documents for context preservation
✅ **Workflow Phases**: Guides through PROPOSE → PLAN → BUILD → VERIFY → CLOSE

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

## Setup — macOS / Linux / WSL

### 1. Copy files to your project

```bash
# From wherever you extracted the zip:
cp -r prefect-template/* prefect-template/.claude your-project/
```

Or clone/copy the individual files into your existing project root.

### 2. Customise CLAUDE.md

Open `CLAUDE.md` and replace the placeholders:

- `[PROJECT_NAME]` — your project name
- `[Brief description of what this project does]` — one-liner
- `[Current phase]` — e.g., "Fresh start", "MVP", "Production"
- `[e.g., Next.js 14, FastAPI, PostgreSQL, S3]` — your actual stack

### 3. Customise product docs

- `docs/PRODUCT-SPEC.md` — describe what you're actually building
- `docs/AI-UAT-CHECKLIST.md` — adjust testing conventions to your stack

### 4. Make hooks executable

```bash
chmod +x .claude/hooks/*.sh
chmod +x lockdown.sh
```

### 5. Lock governance files

```bash
./lockdown.sh lock
```

This removes write permission from CLAUDE.md, PREFECT-POLICY.md, all hooks, and settings.json. Claude's Write/Edit tools and most bash write commands will fail against these files.

### 6. Start Claude Code

```bash
claude
```

The hooks activate automatically — `.claude/settings.json` wires them to Claude Code's lifecycle events. No extra configuration needed.

## Setup — Windows (Native, No WSL)

Claude Code runs natively on Windows since v2.x, but hooks need bash. Here's what to do.

### 1. Install Git for Windows (if you don't have it)

Download from https://gitforwindows.org/ — this gives you Git Bash, which includes bash and the Unix utilities the hooks need.

### 2. Install jq

Git Bash doesn't include jq by default. Install it:

```powershell
winget install jqlang.jq
```

Or download from https://jqlang.github.io/jq/download/ and add to your PATH.

Verify it works from Git Bash:

```bash
echo '{"test": "ok"}' | jq '.test'
# Should output: "ok"
```

### 3. Tell Claude Code to use Git Bash for hooks

This is the critical step. Without it, Claude Code uses cmd.exe for hooks, which can't run bash scripts.

Set the environment variable permanently in PowerShell:

```powershell
[Environment]::SetEnvironmentVariable(
    "CLAUDE_CODE_GIT_BASH_PATH",
    "C:\Program Files\Git\bin\bash.exe",
    [EnvironmentVariableTarget]::User
)
```

Restart your terminal after setting this.

If Git is installed somewhere else, adjust the path. You can find it with:

```powershell
where.exe bash
```

### 4. Copy files to your project

```powershell
xcopy /E /I prefect-template your-project
```

Make sure the `.claude` folder is copied too (can be hidden).

### 5. Customise CLAUDE.md

Same as macOS/Linux — replace `[PROJECT_NAME]` and other placeholders.

### 6. Lockdown (Windows)

The `lockdown.sh` script uses `chmod` which works in Git Bash but has limited effect on NTFS. Two options:

**Option A — Use Git Bash (recommended):**

Open Git Bash and run:

```bash
cd /c/Users/you/your-project
chmod +x .claude/hooks/*.sh lockdown.sh
./lockdown.sh lock
```

**Option B — Use Windows file properties:**

Right-click each governance file → Properties → check "Read-only". This blocks Claude's Write tool but is less comprehensive than chmod.

### 7. Start Claude Code

```powershell
claude
```

Hooks will now execute via Git Bash automatically.

## How It Works

### Layer 1: Prevention (real-time blocking)

**prefect-guard.sh** fires on Write, Edit, and MultiEdit tool call. It:
- Blocks edits to CLAUDE.md, PREFECT-POLICY.md, hooks, and settings.json
- Blocks file creation at project root (unless in the allowlist)
- Blocks directory nesting deeper than 5 levels
- Blocks forbidden directory names (temp, misc, old, backup, scratch, junk, etc.)
- Warns on files exceeding 250 lines
- Resolves symlinks to prevent bypass attempts

**prefect-bash-guard.sh** fires on Bash command. It catches:
- `echo "x" > CLAUDE.md` and similar redirects to protected files
- `sed -i`, `rm`, `mv`, `cp` targeting protected files
- `git commit --no-verify` (prevents skipping test hooks)
- Write operations targeting forbidden directories

Together these two hooks make it extremely difficult for Claude to modify its own governance — even if it tries creative workarounds.

### Layer 2: Detection (post-hoc validation)

**prefect-post-check.sh** runs after Write/Edit and validates the result.

**prefect-audit.sh** scores your project health across 8 dimensions:

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
bash .claude/hooks/prefect-audit.sh
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

**prefect-session-end.sh** fires when Claude finishes responding. It:
- Runs a mini drift audit (root files, file sizes, forbidden dirs)
- Writes a timestamped entry to `docs/SESSION-LOG.md` with:
  - Current branch and last commit
  - Number of drift issues found
  - Staged, modified, and untracked files
- Entries are newest-first so the next session sees the most recent state

The next session reads SESSION-LOG.md and picks up where the previous one left off. No manual handoff writing needed. The file is auto-created on first session end.

## Day-to-Day Usage

### Starting a session

Claude reads CLAUDE.md automatically. The Session Protocol tells it to also check `docs/SESSION-LOG.md`. It states its understanding of the current phase and asks what to work on.

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
bash .claude/hooks/prefect-audit.sh
```

### Recovering context mid-session

Say "prefect check" and Claude will re-read CLAUDE.md, all directives, and confirm the current constraints.

### Running parallel Claude instances

Each instance gets its own feature branch and owns specific files. Governance files are shared read-only. Coordinate file ownership before starting. Merge to main one branch at a time. See the Parallel Instances section in CLAUDE.md for details.

## Customisation

### Adding root files to the allowlist

If your project needs files at root that aren't in the default list (e.g., `Procfile`, `fly.toml`, `vercel.json`), add them in three places:

1. **prefect-guard.sh** — the `ALLOWED_ROOT` array
2. **prefect-audit.sh** — the root cleanliness `case` block
3. **prefect-session-end.sh** — the root cleanliness `case` block

### Changing forbidden directory names

Edit the arrays/patterns in both `prefect-guard.sh` and `prefect-bash-guard.sh`. The defaults block: temp, tmp, misc, stuff, old, backup, bak, scratch, junk, archive.

### Adjusting file size limits

The 250-line limit is in `prefect-guard.sh` (enforcement) and `prefect-audit.sh` (scoring). Change both if you want a different threshold.

### Adding new directives

Prefect supports governance directives as `D-*.md` files at project root:
- `D-ARCH-STRUCTURE.md` — architecture (included)
- `D-WORK-WORKFLOW.md` — workflow (included)
- `D-DATA-MODELS.md` — create when you build your first data model
- `D-ACCESS-CONTROL.md` — create when you implement auth

Don't create directives speculatively. CLAUDE.md says: "No directives until real code demands them."

## What Prefect Does NOT Do

- **No multi-agent orchestration** — one Claude, one session, clear ownership
- **No automatic code formatting** — use your own linter hooks alongside Prefect
- **No CI/CD integration** — Prefect is local governance; add CI when you have code worth scanning
- **No cloud or external dependencies** — everything is local bash scripts and markdown
- **No learning or adaptation** — the rules are deterministic. Claude doesn't evolve them; humans do, via PREFECT-FEEDBACK.md

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

The v5 audit script excludes `venv/`, `.venv/`, `node_modules/`, `__pycache__/`, and other dependency directories automatically. If you see false positives, check you're running the v5+ version — look for `PRUNE_DIRS` near the top of `prefect-audit.sh`.

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

*Prefect Governance Framework v5.1 — Human-owned, AI-enforced.*# Prefect-AI-Governance-Framework
