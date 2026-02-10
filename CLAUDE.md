# CLAUDE.md — [PROJECT_NAME]

## Project Identity
- **What:** [Brief description of what this project does]
- **Phase:** [Current phase — e.g., Fresh start, MVP, Production]
- **Stack:** [e.g., Next.js 14, FastAPI, PostgreSQL, S3]

## Reference Documents
@D-WORK-WORKFLOW.md
@D-ARCH-STRUCTURE.md
@docs/PRODUCT-SPEC.md
@docs/AI-UAT-CHECKLIST.md

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
- NEVER merge code with failing tests, even if unit tests pass
- NEVER push directly to main — use feature branches, merge via PR
- NEVER hardcode secrets, API keys, passwords, or credentials — use environment variables
- NEVER collect personal data without explicit justification and a documented legal basis
- Commit at end of every completed CLOSE phase — no uncommitted multi-feature drift
- git add immediately after creating files — no long-lived untracked files

## Rabbit Hole Rule
If a fix fails 3 times, STOP. Report what was tried, what failed, and your best diagnosis. The human decides next steps. Do not keep retrying — compounding errors causes cascading damage (broken migrations, corrupted models, divergent state).

## Quality Defaults
Always implement comprehensively by default. This means:
- Full test coverage for every feature (unit + integration)
- Comprehensive error handling, not just happy path
- Input validation on all endpoints
- Proper logging
Do not ask "should I add tests?" or "comprehensive or minimal?" — the answer is always comprehensive.

## Privacy by Design (GDPR Article 25)
All development follows privacy principles by default:
- **Data Minimisation** — only collect what is strictly necessary; justify each personal data field
- **Purpose Limitation** — data used only for its stated purpose
- **Storage Limitation** — define retention policies; do not keep data forever
- **Accuracy** — keep personal data correct and up to date
- **Integrity & Confidentiality** — appropriate security measures for all personal data
- **Accountability** — audit trails and documentation for data processing
When designing data models, flag any personal data fields and document the legal basis for collection.

## Security by Design
- No hardcoded secrets — environment variables only, .env in .gitignore
- Dependencies must be audit-clean before merge (pip-audit, npm audit, Snyk)
- SQL injection protection — use parameterised queries only, never string concatenation
- Auth on every endpoint by default — explicitly mark public endpoints, not the other way around
- HTTPS only in production
- Input sanitisation on all user-facing inputs

## Development Workflow
- Read D-WORK-WORKFLOW.md before starting ANY task
- Every change follows: **PROPOSE → PLAN → BUILD → VERIFY → CLOSE**
- PROPOSE phase: ask one question at a time, wait for answer, then next question
- PLAN phase: present detailed options with tradeoffs before execution — human chooses
- Trivial changes (typos, config values) use abbreviated flow (§8)
- After completing a task (BUILD→VERIFY→CLOSE), run /clear before starting the next task to prevent context degradation

| Human says | Claude does |
|---|---|
| "I want to build X" | Enter PROPOSE. Ask clarifying questions (one at a time). |
| "Plan it" | Enter PLAN. Produce structured plan with options. |
| "Approved" / "Build it" | Enter BUILD. Follow plan exactly. |
| "Check it" | Enter VERIFY. Run drift checks + tests. |
| "Ship it" | Enter CLOSE. Update docs, write handoff. |
| "Prefect check" | Re-read governance. Confirm constraints. |
| "Wrap up" | Run CLOSE + session summary. |

## Backend Implementation Order
When building backend features, follow this sequence:
1. **Schemas/Models** — data structures and database models first
2. **Services** — business logic layer
3. **Dependencies** — dependency injection, shared utilities
4. **Routes** — API endpoints (thin layer, delegates to services)
5. **Tests** — comprehensive tests for each layer
This order is proven. Do not deviate.

## Database Conventions
- Table names: plural, snake_case (e.g., `user_sessions`, `audit_logs`)
- Foreign keys: `{singular_table}_id` (e.g., `user_id`, `project_id`)
- Migrations: test the full chain (up + down) before committing
- Database migrations in main branch only — never in feature branches unless unavoidable
- Schema changes require human approval in PLAN phase

## Governance Files — Read Before Acting
| Before you... | Read this first |
|---|---|
| Start any task | D-WORK-WORKFLOW.md |
| Create or move files | D-ARCH-STRUCTURE.md |
| Implement a feature | docs/PRODUCT-SPEC.md (understand what we're building) |
| Write test cases | docs/AI-UAT-CHECKLIST.md (UAT format and conventions) |
| Wonder "where does this go?" | DIRECTORY-POLICY section in D-ARCH-STRUCTURE.md |

## Product Reference
- **docs/PRODUCT-SPEC.md** — What this project does (features, workflows, roadmap)
- **docs/AI-UAT-CHECKLIST.md** — How AI assistants should handle testing
- These are product docs, NOT governance. Read for context when implementing features.

## Session Protocol
**Start:** Read this file → Read `docs/SESSION-LOG.md` (if exists) → State current phase + today's task
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
- Solo developer — keep governance proportional. One-line additions to existing files over new directives.
- No directives beyond D-ARCH-STRUCTURE and D-WORK-WORKFLOW until real code demands them
- Create D-DATA-MODELS.md only when building first data model
- Create D-ACCESS-CONTROL.md only when implementing auth
- No GitHub CI workflows until there's code worth scanning

## Parallel Instances
When running multiple Claude Code sessions (2-3 VSCode instances):
- Each instance gets its own feature branch — no shared branches
- Each instance owns specific files — no two instances edit the same file
- Governance files (CLAUDE.md, directives) are read-only shared resources — no conflicts
- Coordinate file ownership BEFORE starting parallel work (discuss split in one instance first)
- Merge feature branches to main via PR one at a time — resolve interface points sequentially
- Database migrations in main branch only — never in parallel feature branches

## Limits
- Source code: 250 lines max | Directives: 300 lines max | This file: keep concise

---
*Human-owned. Claude may suggest edits but must NEVER modify this file directly.*
