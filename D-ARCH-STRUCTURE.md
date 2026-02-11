# D-ARCH-STRUCTURE — Project Directory Structure Template

> **Policy Area:** ARCH — Architecture
> **Version:** 2.0
> **Last Reviewed:** 2026-02-11
> **Owner:** Human+AI
> **References:** D-WORK-WORKFLOW.md
> **Enforcement:** Active (CLAUDE.md rule) + Hard (hooks)

---

## Purpose

**This is a TEMPLATE for projects using Prefect.** Customize it for your project's specific directory structure and naming conventions.

This directive defines the only approved directories and file locations for your project. Any file or directory not listed here is unauthorized. The AI must consult this directive before creating any file and must update this directive (with human approval) before creating any new directory.

**For the Prefect Framework's own structure**, see the "Framework Directory Structure" section in README.md.

---

## Instructions

### INS-DA1-001: Approved Directory Tree

**IMPORTANT:** This is an EXAMPLE structure. Replace it with your project's actual directories. The following shows common patterns for different project types — choose one or adapt as needed.

**Option 1: Simple CLI/Library Project**
```
/project-root/
├── src/                     # Source code
│   ├── core/               # Core functionality
│   ├── utils/              # Utilities (max 5 files)
│   └── cli/                # CLI interface (if applicable)
├── tests/                   # Tests mirror src/ structure
│   ├── test_core/
│   └── test_utils/
├── docs/                    # Documentation (non-governance)
└── [governance files at root — see PREFECT-POLICY.md Section 4]
```

**Option 2: Web Application (Frontend + Backend)**
```
/project-root/
├── backend/
│   ├── app/
│   │   ├── models/         # Data models
│   │   ├── routes/         # API endpoints
│   │   ├── services/       # Business logic
│   │   └── core/           # Config, middleware
│   ├── tests/              # Mirrors backend/app/ structure
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/     # UI components
│   │   ├── pages/          # Page components
│   │   ├── services/       # API client
│   │   └── utils/          # Utilities (max 5 files)
│   └── package.json
├── scripts/                 # Build/deploy scripts
├── docs/                    # Documentation
└── [governance files at root — see PREFECT-POLICY.md Section 4]
```

**Option 3: Monorepo/Multi-Service**
```
/project-root/
├── services/
│   ├── api/                # API service
│   │   ├── src/
│   │   └── tests/
│   ├── worker/             # Background worker
│   │   ├── src/
│   │   └── tests/
│   └── web/                # Web frontend
│       ├── src/
│       └── tests/
├── shared/                  # Shared code
│   ├── types/
│   └── utils/
├── docs/                    # Documentation
└── [governance files at root — see PREFECT-POLICY.md Section 4]
```

**After choosing a structure, delete the unused options and list ONLY your project's approved directories.**

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

If a naming conflict arises, document the resolution and rationale in PREFECT-FEEDBACK.md for governance review.

### INS-DA1-008: Empty Directory Prohibition

No empty directories may exist in the project. If a directory is created, it must contain at least one file. If all files are removed from a directory, the directory must also be removed and its entry evaluated in this directive.

### INS-DA1-009: Data Model Directory Changes

When the approved tree is modified to add new directories for data models or schemas, document the change and its purpose in PREFECT-FEEDBACK.md. If you create a D-DATA-MODELS.md directive (recommended when you have multiple models), update it to reflect the new model locations.

### INS-DA1-010: New Top-Level Directory Justification

When a new top-level directory is added (e.g., a new service, a new frontend app), document the rationale in PREFECT-FEEDBACK.md, including:
- Why the new directory is needed
- What alternatives were considered
- How it fits into the overall architecture

This creates a decision record for future reference.

---

## Enforcement Configuration

### folderslint (.folderslintrc)

**Optional:** If you want automated linting of directory structure, create a `.folderslintrc` file matching your approved directories from INS-DA1-001.

**Example for Option 2 (Web Application):**
```json
{
  "root": ".",
  "rules": [
    "backend/app/models/*",
    "backend/app/routes/*",
    "backend/app/services/*",
    "backend/app/core/*",
    "backend/tests/**",
    "frontend/src/components/*",
    "frontend/src/pages/*",
    "frontend/src/services/*",
    "frontend/src/utils/*",
    "scripts/*",
    "docs/*"
  ]
}
```

**Replace these rules with your project's actual approved directories.**

---

## Audit Checklist

**Customize this checklist based on your project's approved structure:**

- [ ] Every directory in the project exists in your customized INS-DA1-001
- [ ] No directories exceed 4 levels of nesting (INS-DA1-003)
- [ ] No forbidden directory names exist (INS-DA1-004)
- [ ] Test files mirror source structure (INS-DA1-005)
- [ ] Utils directories contain ≤ 5 files (INS-DA1-006) — adjust cap if needed
- [ ] No duplicate-purpose directories (INS-DA1-007)
- [ ] No empty directories (INS-DA1-008)
- [ ] Root contains only allowed files (PREFECT-POLICY.md Section 4)
- [ ] Documentation exists for structural changes (INS-DA1-009, INS-DA1-010)
