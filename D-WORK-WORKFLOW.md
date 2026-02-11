# D-WORK-WORKFLOW — Development Workflow Protocol

> **Policy Area:** WORK  
> **Version:** 1.2  
> **Status:** Active  
> **Enforcement:** MUST (per RFC 2119)  
> **Purpose:** How every feature, fix, and change moves from idea to shipped code with Claude Code. Includes mandatory UAT checkpoints at each phase.

---

## 1. The Five Phases

Every unit of work follows five phases. No phase can be skipped.

```
PROPOSE → PLAN → BUILD → VERIFY → CLOSE
```

---

## 2. Phase 1: PROPOSE

**Who leads:** Human  
**What happens:** Human describes what they want. Claude asks clarifying questions. No code, no files yet.

### Claude MUST:
1. Restate the request in one sentence to confirm understanding
2. Ask 2-5 clarifying questions about scope, edge cases, and constraints
3. Identify which governance files are relevant
4. Flag anything that conflicts with CLAUDE.md constraints or active directives
5. NOT write any code, NOT create any files

### UAT Checkpoint — PROPOSE:
6. Ask: "Is this user-facing?" If yes:
   - "What are the acceptance criteria? Are there existing test cases in your test management tool?"
   - If no acceptance criteria exist: **define them now**, in business language, before proceeding
   - Acceptance criteria must include: happy path, at least one edge case, expected error states
   - Write criteria in plain language ("User sees X") not code ("returns 200")

### Gate: PROPOSE → PLAN
Human says: "Plan it" or any clear affirmative. For user-facing features, acceptance criteria must exist before this gate opens.

**If human says "just do it":**  
Claude responds: *"Let me give you a 30-second plan first so we don't build the wrong thing. Here's what I'd do: [quick plan]. Sound good?"*

---

## 3. Phase 2: PLAN

**Who leads:** Claude  
**What happens:** Claude produces a structured plan. Human reviews and approves.

### Claude MUST produce:

```markdown
## Plan: [Feature/Fix Name]

**Scope:** [One sentence]
**Touches:** [Governance areas affected]
**Acceptance Criteria:** [List from PROPOSE, or reference test case IDs]

### Files to Create
- path/to/file.ts — purpose

### Files to Modify  
- path/to/existing.ts — what changes and why

### Files NOT Touched
- [Explicitly list to prevent scope creep]

### Governance Updates Required
- [ ] Which docs need updating and why

### Risks & Decisions
- [Anything needing human input]

### Estimated Scope
- Files: [count] | Complexity: Low / Medium / High
```

### Plan Rules:
- **Max 15 files** per plan. If more needed, split into sequential plans.
- **No speculative features.** Current scope only.
- **Name every file.** "Various updates" is not a plan.
- **Governance updates are part of the plan**, not an afterthought.
- **Acceptance criteria are part of the plan.** No plan is approved without them for user-facing work.

### Gate: PLAN → BUILD
Human says: "Approved" / "Build it" / "Approved with changes: [modifications]"

Or rejects: "Change X" → revise plan. "Too big" → split. "Wrong approach" → back to PROPOSE.

---

## 4. Phase 3: BUILD

**Who leads:** Claude  
**What happens:** Claude implements the approved plan. Only phase where code gets written.

### Claude MUST:
1. **Follow the plan exactly.** No files not in the plan. No features not in the plan.
2. **Build in this order:**
   - Governance updates FIRST (docs before code)
   - Data models / schemas
   - Business logic / services
   - API routes / handlers
   - UI components (if applicable)
   - Tests
3. **After every 3-5 files**, pause and report:
   - "✅ Created: [files]. ⏳ Remaining: [files]. Any concerns?"
4. **If the plan needs to change mid-build:**
   - STOP building
   - Explain what changed
   - Propose a plan amendment
   - Wait for human approval

### UAT Rules During BUILD:
5. **Implement exact behavior from acceptance criteria.** If criteria say "Welcome back, John!" — the code says "Welcome back, John!", not "Hi John".
6. **Handle every edge case listed in the criteria.** Don't skip them, don't defer them.
7. **Do not add behavior not in the criteria.** No "while I'm here, I'll also add..." — that's scope creep.
8. **If criteria are ambiguous, STOP and ask.** Never guess intent. The #1 AI failure mode is confidently building the wrong thing.

### Build Rules:
- **250-line limit** on source files. Split before writing if it'll exceed.
- **No new directories** unless they were in the approved plan.
- **Tests ship with the feature**, not "later."
- **No new dependencies** unless in the approved plan.

### When Claude Gets Stuck:
```
🤔 Decision point not covered by the plan:
   [Situation]
   Option A: [approach + tradeoff]
   Option B: [approach + tradeoff]
   My recommendation: [A or B] because [reason].
   Which do you prefer?
```

---

## 5. Phase 4: VERIFY

**Who leads:** Claude (checks), Human (acceptance)

### Claude MUST perform:

**5.1 Governance Drift Check:**
```
✅ / ❌ All new files in approved directories
✅ / ❌ All new models documented
✅ / ❌ All modified files were in the plan
✅ / ❌ No files exceed 250-line limit
✅ / ❌ No unplanned dependencies added
```

**5.2 UAT Self-Test:**
```
For each acceptance criterion:
✅ / ❌ [Criterion 1] — [how verified]
✅ / ❌ [Criterion 2] — [how verified]
✅ / ❌ [Edge case 1] — [how verified]
✅ / ❌ [Error state 1] — [how verified]
```

Claude walks through each acceptance criterion and verifies the code actually implements it. Not "I think it works" — trace the specific code paths that satisfy each criterion.

**5.3 Plan Compliance:**
```
✅ / ❌ All planned files created
✅ / ❌ All planned governance updates made
✅ / ❌ No unplanned files created
```

**5.4 Drift Score** (if available): `bash .claude/hooks/prefect-audit.sh`

### Gate: VERIFY → CLOSE
Human says: "Looks good" / "Ship it" → proceed to CLOSE.  
Or: "Fix X" → back to BUILD. "Wrong thing" → back to PROPOSE.

**Failing UAT self-test blocks CLOSE.** Even if governance checks pass and drift score is clean, if acceptance criteria aren't met, we go back to BUILD.

---

## 6. Phase 5: CLOSE

**Who leads:** Claude

### Claude MUST:
1. **Update changelog** in relevant governance file:
   ```
   ## [Session YYYY-MM-DD] — Completed: [what], Files: [count], Decisions: [any]
   ```

2. **Write handoff note:**
   ```
   **Done:** [summary]  |  **Next:** [suggested]  |  **Watch out:** [issues]  |  **Drift:** [score]
   ```

3. **UAT documentation in commits and PRs:**
   - Commit messages reference acceptance criteria or test case IDs:
     `feat: Add login form (UAT: login-happy-path, login-invalid-creds, login-empty-fields)`
   - PR descriptions include UAT self-test results and link to acceptance criteria

4. **Log governance observations** to PREFECT-FEEDBACK.md if the plan changed mid-build, a directive didn't cover something, or a rule was too strict/loose.

---

## 7. Session Protocol

### Session Start
Claude reads CLAUDE.md and states: project, current phase, last session's work, active directives, drift score.

### Session End
Human says "wrap up" → Claude runs CLOSE for in-progress work, then provides session summary: tasks completed, tasks in progress, governance updates, drift score, recommended next session.

### Mid-Session Recovery
Human says "prefect check" → Claude re-reads CLAUDE.md + active directives, confirms current task, phase, and active constraints.

---

## 8. Scaling Workflow Intensity

### Trivial (< 5 min, 1-2 files, no new patterns)
Not user-facing: PROPOSE + PLAN collapsed → BUILD → quick VERIFY → commit.
User-facing: Still needs acceptance criteria, but can be one-liner.

### Standard (5-60 min, 3-10 files)
Full flow as described above.

### Complex (1+ hours, 10+ files, new patterns)
- Write plan to `plan.md` file (survives context compaction)
- Extra checkpoints (every 2-3 files)
- Full drift audit in VERIFY
- Full UAT self-test against every criterion
- Document architectural decisions in PREFECT-FEEDBACK.md

---

*Enforced by CLAUDE.md reference. Hooks provide hard enforcement for structural rules. Human is the gate between phases. UAT self-test gates VERIFY → CLOSE.*
