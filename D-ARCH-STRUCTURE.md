# D-ARCH-STRUCTURE — Project Directory Structure

> **Policy Area:** ARCH — Architecture
> **Version:** 1.0
> **Last Reviewed:** 2025-02-08
> **Owner:** Human+AI
> **References:** D-ARCH-STACK.md, D-DATA-MODELS.md
> **Enforcement:** Active (CLAUDE.md rule) + Hard (folderslint)

---

## Purpose

This directive defines the only approved directories and file locations for the project. Any file or directory not listed here is unauthorized. The AI must consult this directive before creating any file and must update this directive (with human approval) before creating any new directory.

---

## Instructions

### INS-DA1-001: Approved Directory Tree

The following is the complete approved structure. Directories not listed are forbidden.

```
/project-root/
├── backend/
│   ├── app/
│   │   ├── models/          # SQLAlchemy models ONLY
│   │   ├── routes/          # API route handlers ONLY
│   │   ├── services/        # Business logic ONLY
│   │   ├── schemas/         # Pydantic request/response schemas ONLY
│   │   └── core/            # Config, auth middleware, database setup
│   ├── tests/               # Mirrors backend/app/ structure exactly
│   │   ├── test_models/
│   │   ├── test_routes/
│   │   ├── test_services/
│   │   └── conftest.py
│   ├── migrations/           # Alembic migrations ONLY
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/       # Reusable UI components
│   │   ├── pages/            # Page-level components (one per route)
│   │   ├── services/         # API client functions
│   │   ├── hooks/            # Custom React hooks
│   │   ├── utils/            # Pure utility functions (max 5 files)
│   │   └── types/            # TypeScript type definitions
│   ├── public/               # Static assets
│   └── package.json
├── scripts/                  # Build, deploy, utility scripts
├── docs/                     # Non-governance documentation (guides, diagrams)
└── [governance files at root — see PREFECT-POLICY.md Section 4]
```

### INS-DA1-002: File Creation Protocol

Before creating ANY new file, the AI must:

1. Identify the target directory in the approved tree above
2. If directory exists in tree → proceed, output PREFECT CHECK
3. If directory does NOT exist → STOP, do not create the file
4. Write a proposal to PREFECT-FEEDBACK.md (type: "Directive Gap")
5. Wait for human to approve and update this directive

**The AI may never create a directory that is not listed in INS-DA1-001.**

### INS-DA1-003: Directory Depth Limit

No directory may be nested more than 4 levels from project root.

- ✅ `/backend/app/models/user.py` (4 levels) — allowed
- ❌ `/backend/app/services/auth/providers/oauth/google.py` (6 levels) — forbidden
- Fix: flatten to `/backend/app/services/auth_oauth_google.py` or restructure

### INS-DA1-004: Forbidden Directory Patterns

The following directory names may never be created anywhere in the project:

- `temp`, `tmp`, `old`, `backup`, `bak`, `archive`
- `misc`, `stuff`, `other`, `random`
- `helpers` (use `utils/` if needed, but only in approved locations)
- `lib` (use `core/` for shared code)
- `new`, `v2`, `refactored` (version in git, not in directory names)

### INS-DA1-005: Test File Placement

Test files MUST mirror the source structure exactly:

- Source: `backend/app/services/project_service.py`
- Test: `backend/tests/test_services/test_project_service.py`
- Pattern: `test_{source_filename}.py`

Test files are NEVER placed next to source files. They always live under `/tests/`.

### INS-DA1-006: Utils Directory Cap

The `frontend/src/utils/` directory is limited to 5 files maximum. If the cap is reached:

- Evaluate whether a "utility" should actually be a service, hook, or component
- If genuinely a utility, consider whether an existing utility file can absorb it
- Only as last resort: request a cap increase via PREFECT-FEEDBACK.md

This prevents utils from becoming a dumping ground.

### INS-DA1-007: No Duplicate-Purpose Directories

The project may never contain two directories serving the same purpose. Examples of forbidden duplicates:

- Both `utils/` and `helpers/`
- Both `types/` and `interfaces/`
- Both `services/` and `api/` (for client-side API calls)
- Both `models/` and `entities/`

If a naming conflict arises, document the resolution as an ADR in D-ARCH-STACK.md.

### INS-DA1-008: Empty Directory Prohibition

No empty directories may exist in the project. If a directory is created, it must contain at least one file. If all files are removed from a directory, the directory must also be removed and its entry evaluated in this directive.

### INS-DA1-009: Cross-Reference — Data Models

When the approved tree is modified to add a new directory under `backend/app/models/` or `backend/app/schemas/`, the sibling directive **D-DATA-MODELS.md** must also be updated to reflect any new model locations.

### INS-DA1-010: Cross-Reference — Tech Stack

When a new top-level directory is added (e.g., a new service, a new frontend app), an Architecture Decision Record must be added to **D-ARCH-STACK.md** documenting why the new directory was needed.

---

## Enforcement Configuration

### folderslint (.folderslintrc)

```json
{
  "root": ".",
  "rules": [
    "backend/app/models/*",
    "backend/app/routes/*",
    "backend/app/services/*",
    "backend/app/schemas/*",
    "backend/app/core/*",
    "backend/tests/**",
    "backend/migrations/*",
    "frontend/src/components/*",
    "frontend/src/pages/*",
    "frontend/src/services/*",
    "frontend/src/hooks/*",
    "frontend/src/utils/*",
    "frontend/src/types/*",
    "frontend/public/*",
    "scripts/*",
    "docs/*"
  ]
}
```

---

## Audit Checklist

- [ ] Every directory in the project exists in INS-DA1-001
- [ ] No directories exceed 4 levels of nesting (INS-DA1-003)
- [ ] No forbidden directory names exist (INS-DA1-004)
- [ ] Test files mirror source structure (INS-DA1-005)
- [ ] `frontend/src/utils/` contains ≤ 5 files (INS-DA1-006)
- [ ] No duplicate-purpose directories (INS-DA1-007)
- [ ] No empty directories (INS-DA1-008)
- [ ] Root contains only allowed files (PREFECT-POLICY.md Section 4)
- [ ] All cross-referenced directives are in sync (INS-DA1-009, INS-DA1-010)
