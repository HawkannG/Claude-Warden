# PREFECT-POLICY.md — Constitution for AI-Assisted Project Governance

> **Version:** 2.0
> **Type:** Constitution (highest governance authority)
> **Owner:** Human ONLY — AI may never modify this file
> **Max Size:** 400 lines (this file) | 300 lines (directives) | 80 lines (CLAUDE.md)

---

## 0. Philosophy

AI coding assistants are powerful but stateless. They forget rules, create drift, and accumulate entropy over long sessions. This policy creates a structural immune system — governance artifacts that persist even when the AI's context does not.

**Three layers of governance exist:**

| Layer | Purpose | Mechanism |
|-------|---------|-----------|
| **Soft governance** | Tell the AI what to do | `.md` files (this policy + directives) |
| **Active governance** | Make the AI confirm before acting | CLAUDE.md checklist + recursive output rules |
| **Hard governance** | Prevent violations mechanically | Linters, CI checks, pre-commit hooks |

Soft governance alone is insufficient. AI can choose to ignore documentation. This policy is the foundation, but enforcement tooling (folderslint, ls-lint, CI pipeline checks, and eventually the Prefect audit tool) is the mechanism that makes it stick.

---

## 1. Governance Hierarchy

```
PREFECT-POLICY.md                    ← Constitution (this file)
│                                       Human-owned. Defines all policy areas.
│                                       AI may NEVER edit.
│
├── CLAUDE.md                         ← Operating Instructions
│                                       Short index (~50 rules max).
│                                       References directives by policy area.
│                                       Human-owned. AI may suggest changes.
│
├── PREFECT-FEEDBACK.md               ← Feedback Loop
│                                       AI writes findings here.
│                                       Human reviews and adjusts policy.
│                                       The mechanism for self-improvement.
│
└── D-{AREA}-{NAME}.md               ← Directives
    │                                    Max 300 lines each.
    │                                    Must reference a registered Policy Area.
    │                                    Human approves creation. AI drafts content.
    │
    └── ## Sections within directives  ← Instructions & Guidelines
         Each section = one instruction.
         Each has a rule ID: INS-{D##}-{###}
         AI maintains. Human reviews.
```

**Rules of the hierarchy:**

- A directive CANNOT exist without a registered Policy Area as parent
- A directive MUST reference its parent Policy Area in its header
- A directive MAY reference sibling directives (cross-references)
- Instructions live as sections WITHIN directives, never as separate files
- Every instruction has a unique rule ID for audit traceability
- No governance file may exceed its size limit (see Section 5)

---

## 2. Policy Area Registry

Policy Areas are the top-level domains of governance. They are defined ONLY in this file. AI may never create, rename, or remove a Policy Area. To add a new Policy Area, a human must edit this section manually.

| ID | Policy Area | Description | Max Directives |
|----|------------|-------------|----------------|
| `ARCH` | Architecture | Project structure, tech stack, dependencies, directory layout | 4 |
| `DATA` | Data Governance | Data models, relationships, migrations, API contracts | 3 |
| `ACCESS` | Access & Security | Authentication, authorization, roles, permissions, security ops | 2 |
| `WORKFLOW` | Development Workflow | Session protocol, change management, status tracking | 3 |
| `QUALITY` | Quality Assurance | Testing strategy, code standards, review process | 2 |

**Registry rules:**

- Maximum 7 Policy Areas (more than 7 becomes unmanageable)
- Each Policy Area has a max directive count to prevent sprawl
- To propose a new Policy Area, AI writes to PREFECT-FEEDBACK.md with type "Policy Gap"
- Human evaluates, and if approved, manually adds the area to this table
- Removing a Policy Area requires archiving all its directives first

---

## 3. Directive Rules

### 3.1 Naming Convention

All directives follow: `D-{AREA}-{NAME}.md`

- `{AREA}` = Policy Area ID from registry (e.g., `ARCH`, `DATA`)
- `{NAME}` = Short descriptive name, UPPERCASE (e.g., `STRUCTURE`, `MODELS`)
- Examples: `D-ARCH-STRUCTURE.md`, `D-DATA-MODELS.md`, `D-ACCESS-CONTROL.md`

### 3.2 Location

All directives live at the **project root**. No nesting. No subdirectories for governance.

### 3.3 Required Header

Every directive MUST begin with:

```markdown
# D-{AREA}-{NAME} — [Title]

> **Policy Area:** {AREA} — {Area Name}
> **Version:** {N.N}
> **Last Reviewed:** {YYYY-MM-DD}
> **Owner:** {Human / Human+AI}
> **References:** [sibling directives, comma-separated]
> **Enforcement:** {Soft | Active | Hard}
```

### 3.4 Required Body Structure

```markdown
## Purpose
One paragraph: what this directive governs and why.

## Instructions
### INS-{D##}-001: {Rule title}
{Rule description — specific, measurable, unambiguous}

### INS-{D##}-002: {Rule title}
{Rule description}

## Audit Checklist
- [ ] {Checkable statement derived from each instruction}
```

### 3.5 Creation Protocol

1. AI identifies a governance need not covered by existing directives
2. AI writes a proposal to PREFECT-FEEDBACK.md (type: "Directive Proposal")
3. Human reviews and confirms the Policy Area parent
4. Human verifies the Policy Area hasn't hit its max directive count
5. AI drafts the directive with proper header and structure
6. Human reviews and approves
7. Directive is added to CLAUDE.md's policy area index

**AI may NEVER create a directive file without completing steps 1-6.**

### 3.6 Cross-References

Directives often interact (e.g., a model change usually means an API contract change). Cross-references are declared in the header's `References:` field. When an instruction in one directive is triggered, the AI must check whether referenced siblings are also affected.

---

## 4. Root Directory Rules

### 4.1 Allowed Root Files

The project root may ONLY contain:

- `PREFECT-POLICY.md` (this file)
- `CLAUDE.md` (operating instructions)
- `PREFECT-FEEDBACK.md` (feedback loop)
- `README.md` (project overview — a project file, not governance)
- `D-{AREA}-{NAME}.md` files (registered directives only)
- Standard config files (`.gitignore`, `package.json`, `requirements.txt`, `docker-compose.yml`, `Makefile`, `.folderslintrc`, `.ls-lint.yml`, etc.)

### 4.2 Forbidden at Root

- Unregistered `.md` files (any `.md` not matching above = unauthorized)
- Temporary, backup, or log files
- Source code files
- Directories not approved in D-ARCH-STRUCTURE.md

---

## 5. Size Limits

| File | Max Lines | When Exceeded |
|------|-----------|---------------|
| `PREFECT-POLICY.md` | 400 | Tighten language. Never expand to compensate. |
| `CLAUDE.md` | 80 | Move detail into directives. CLAUDE.md is an index. |
| `PREFECT-FEEDBACK.md` | No limit, but max 20 open entries | Incorporate feedback, then mark resolved. |
| Any `D-*.md` | 300 | Split into two directives (requires human approval + Policy Area capacity). |
| Any source code file | 250 | Refactor into smaller modules. |

---

## 6. CLAUDE.md Rules

CLAUDE.md is the AI's short-term operating manual. It is an INDEX, not an encyclopedia.

**Required content:** current phase and scope, policy area index, absolute rules (max 10), recursive governance check, forbidden patterns.

**Rules:** Human-owned. Max 80 lines. Written assuming zero memory. Specific over general. Updated after every drift incident.

**Recursive governance check** — CLAUDE.md MUST include a rule requiring the AI to output a governance confirmation before any file-creating or structure-changing action. This keeps governance in the conversation context through the "recursive rule" principle.

See the CLAUDE.md template distributed with this policy.

---

## 7. Feedback Loop — Self-Improving Governance

### 7.1 Feedback Types

| Type | Meaning |
|------|---------|
| `Policy Gap` | Situation the policy doesn't cover |
| `Directive Gap` | A directive is missing or incomplete |
| `Directive Proposal` | AI proposes a new directive |
| `Instruction Unclear` | AI misinterpreted a rule |
| `Rule Too Rigid` | A rule blocked legitimate work |
| `Rule Too Loose` | A rule didn't prevent drift |
| `Drift Detected` | Actual state doesn't match governed state |

### 7.2 Entry Format

```markdown
## FB-{NNN} [{YYYY-MM-DD}] [{Trigger}]
- **Drift Score Delta**: {current} (was {previous})
- **Type**: {type}
- **Policy Area**: {AREA ID or "None — new area needed"}
- **Directive**: {D-file or "None — new directive needed"}
- **Finding**: {What happened}
- **Suggestion**: {What should change}
- **For Human**: {Specific question requiring human decision}
- **Status**: Open | Incorporated | Rejected | Deferred
```

### 7.3 Scheduled Feedback (Epochs)

| Trigger | Frequency | Scope |
|---------|-----------|-------|
| **Mini-audit** | Every 5 sessions | Structure + staleness check |
| **Full audit** | Every 15 sessions | All drift detection across all directives |
| **Event-driven** | On new file, dependency, or model change | Targeted check on affected area |
| **On-demand** | Human-triggered | Full or targeted audit |

### 7.4 Drift Score

Composite health metric (0 = perfect, 100 = ungovernable):

| Component | Weight |
|-----------|--------|
| Unauthorized files at root | 15 |
| Unauthorized directories | 15 |
| Undocumented data models | 20 |
| Unregistered API endpoints | 15 |
| Stale directives (14+ days, active project) | 10 |
| Orphan code (no governance trail) | 10 |
| Open feedback entries (20+) | 10 |
| Repeated CLAUDE.md forbidden patterns | 5 |

**If drift score increases for 3 consecutive epochs → trigger Level 4 Freeze.**

### 7.5 Feedback Lifecycle

```
AI Detects Issue → Writes to PREFECT-FEEDBACK.md
        ↓
Human Reviews (next session or scheduled)
        ↓
   ┌─── Incorporate → Update policy/directive → Mark "Incorporated"
   ├─── Reject → Add reasoning → Mark "Rejected"
   └─── Defer → Set review date → Mark "Deferred"
        ↓
Next Epoch: Did drift score decrease?
   ├── Yes → Governance improved
   └── No → Re-enter loop, adjust further
```

---

## 8. Enforcement Escalation

| Level | Name | Trigger | Action |
|-------|------|---------|--------|
| 1 | **Notice** | Minor drift | AI flags in feedback, continues |
| 2 | **Warning** | Directive violation | AI flags + outputs warning, continues with caution |
| 3 | **Block** | Structural violation (unauthorized file/dir) | AI stops, requests human approval |
| 4 | **Freeze** | Drift score > 50 OR 3 consecutive increases | Stop feature work. Full reconciliation session. |

---

## 9. Getting Started

### New Project
1. Copy PREFECT-POLICY.md, CLAUDE.md template, PREFECT-FEEDBACK.md to root
2. Customize Policy Areas in Section 2
3. Create initial directives for each active area
4. Configure folderslint / ls-lint for hard enforcement
5. Start coding

### Existing (Messy) Project
1. Place this file at root
2. Create CLAUDE.md: "Read PREFECT-POLICY.md. Audit this project. Write drift report to PREFECT-FEEDBACK.md."
3. Clean root directory first — identify unauthorized .md files
4. Map existing docs to Policy Areas — merge into directives
5. Document current state (what IS), not desired state
6. Incrementally correct toward desired state, prioritized by drift score weights

---

*Changes to this constitution require a PREFECT-FEEDBACK.md entry and human approval.*
