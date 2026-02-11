# CLAUDE.md — [Project Name]

## Project Identity
- **What:** Test management platform connecting backlog tools with structured UAT workflows
- **Phase:** Fresh start — governance in place, building from zero
- **Stack:** [UPDATE: e.g., Next.js 14, FastAPI, PostgreSQL, S3]

## Absolute Rules
- NEVER edit PREFECT-POLICY.md — suggest changes in chat, human edits
- NEVER edit CLAUDE.md — suggest changes in chat, human edits
- NEVER edit anything in .claude/hooks/ — suggest changes in chat, human edits
- NEVER edit .claude/settings.json — suggest changes in chat, human edits
- NEVER use bash commands to write/modify/delete protected files (the above four rules apply to ALL tools, not just Write/Edit)
- NEVER create files at project root unless registered in prefect-guard.sh
- NEVER create directories named temp, misc, old, backup, scratch, junk
- NEVER exceed 5 directory levels from root
- NEVER add dependencies without documenting in DECISIONS section of ARCHITECTURE.md
- NEVER modify access control or auth without explicit human approval
- NEVER skip the workflow phases — read D-WORK-WORKFLOW.md
- NEVER implement a user-facing feature without acceptance criteria defined first
- NEVER assume requirements not stated in test cases — ask, don't guess
- NEVER merge code with failing UAT tests, even if unit tests pass
- NEVER push directly to main — use feature branches, merge via PR
- Commit at end of every completed CLOSE phase — no uncommitted multi-feature drift

## Development Workflow
- Read D-WORK-WORKFLOW.md before starting ANY task
- Every change follows: **PROPOSE → PLAN → BUILD → VERIFY → CLOSE**
- UAT checkpoints are embedded in each phase — see D-WORK-WORKFLOW.md
- Trivial changes (typos, config values) use abbreviated flow (§8)

| Human says | Claude does |
|---|---|
| "I want to build X" | Enter PROPOSE. Ask clarifying questions. |
| "Plan it" | Enter PLAN. Produce structured plan. |
| "Approved" / "Build it" | Enter BUILD. Follow plan exactly. |
| "Check it" | Enter VERIFY. Run drift checks + UAT self-test. |
| "Ship it" | Enter CLOSE. Update docs, write handoff. |
| "Prefect check" | Re-read governance. Confirm constraints. |
| "Wrap up" | Run CLOSE + session summary. |

## Governance Files — Read Before Acting
| Before you... | Read this first |
|---|---|
| Start any task | D-WORK-WORKFLOW.md |
| Create or move files | D-ARCH-STRUCTURE.md |
| Implement a feature | docs/PRODUCT-SPEC.md (understand what we're building) |
| Write test cases | docs/AI-UAT-CHECKLIST.md (UAT format and conventions) |
| Wonder "where does this go?" | DIRECTORY-POLICY section in D-ARCH-STRUCTURE.md |

## Product Reference
- **docs/PRODUCT-SPEC.md** — What BacklogBridge does (features, workflows, roadmap)
- **docs/AI-UAT-CHECKLIST.md** — How AI assistants should work with BacklogBridge's UAT
- These are product docs, NOT governance. Read for context when implementing features.

## Session Protocol
**Start:** Read this file → Read last handoff → State current phase + today's task  
**Mid-session:** Every 5 file changes, verify no drift  
**End:** Update changelog → Write handoff → Run `bash .claude/hooks/prefect-audit.sh`  
**Context recovery:** "prefect check" → re-read this file + directives, confirm constraints

## Forbidden Patterns
- Do not create utility/helper dumping-ground files — find the proper module
- Do not put source files at directory root — always in a subdirectory
- Do not write "we'll add tests later" — tests ship with the feature
- Do not install packages without plan approval
- Do not create new .md governance files at root — per PREFECT-POLICY.md §1.2
- Do not implement features beyond what test cases describe — no "helpful" extras
- Do not edit files owned by another parallel Claude instance — check your plan

## Current Constraints
- No directives beyond D-ARCH-STRUCTURE and D-WORK-WORKFLOW until real code demands them
- Create D-DATA-MODELS.md only when building first data model
- Create D-ACCESS-CONTROL.md only when implementing auth
- No GitHub CI workflows until there's code worth scanning
- BacklogBridge MUST dogfood its own UAT process — we eat our own cooking

## Parallel Instances
When running multiple Claude Code sessions (2-3 VSCode instances):
- Each instance gets its own feature branch — no shared branches
- Each instance owns specific files — no two instances edit the same file
- Governance files (CLAUDE.md, directives) are read-only shared resources — no conflicts
- Coordinate file ownership BEFORE starting parallel work (discuss split in one instance first)
- Merge feature branches to main via PR one at a time — resolve interface points sequentially

## Limits
- Source code: 250 lines max | Directives: 300 lines max | This file: keep concise

---
*Human-owned. Claude may suggest edits but must NEVER modify this file directly.*
