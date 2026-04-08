---
name: demand-triage
description: Use immediately after codebase discovery to classify task scale and determine which workflow steps are required vs. optional.
---

# Demand Triage

Use this skill to classify a task's scale and adapt the workflow intensity accordingly. This prevents over-processing small tasks while maintaining full rigor for complex work.

## When to run triage

Run triage **after** codebase discovery (the `repo-exploration` skill) but **before** planning or implementation. Triage requires evidence from reading the codebase — do not classify based on the request text alone.

## Classification criteria

After reading the relevant files, classify the task using observable criteria:

### Small

All of the following must be true:

- Affects **a single file** (or a single file plus its direct test file)
- No contract changes (API request/response shapes, event schemas, public interfaces)
- No schema or migration changes
- No cross-module import changes (does not add or remove dependencies between modules)
- No auth, permission, or security logic changes
- No breaking changes to existing consumers
- The change is **well-understood** — you can describe exactly what to do before starting

Examples: typo fix, copy/label change, simple validation rule, single-function bug fix, adding a log line, updating a config value.

### Medium

Any of the following:

- Affects **2–5 files** within the same module
- Requires minor design adjustment but no architectural change
- Adds a new function or small feature within an existing pattern
- No breaking changes, no schema migration, no auth changes

Examples: adding a new API field with validation, refactoring a function and updating callers, adding a new UI component following existing patterns.

### Large

Any of the following:

- Affects **multiple modules** or crosses module boundaries
- Requires architectural change or new patterns
- Involves schema migration, contract breaking changes, or permission model changes
- Touches auth, security, payment, or audit logic
- Requires coordination between multiple agent roles

Examples: new feature spanning API + service + UI, database migration, permission system change, new integration with external service.

## Uncertainty rule

If classification is uncertain, **default to Medium**. Never default to Small when unsure — the cost of under-processing a Medium task is higher than the cost of slightly over-processing a Small one.

## Hard blockers (force non-Small)

The following characteristics **always** force Medium or Large, regardless of file count:

- Auth or permission logic changes → Medium minimum
- Security-sensitive code changes → Medium minimum
- Schema or migration changes → Large
- Contract or API breaking changes → Large
- Cross-service or cross-deployment changes → Large

## Output format

After classification, state:

```
[SCALE: SMALL | MEDIUM | LARGE]
Reason: [1–2 sentences explaining why, based on evidence from codebase discovery]
Files affected: [list]
```

## Workflow adaptation by scale

### Small tasks — conditional simplifications

When a task is classified as Small, the following workflow steps are **skippable** (may be skipped unless the task specifically requires them):

- **Full planning agent** — replace with a 1–2 sentence inline plan stating what will change and why
- **Critic review** — skip unless the change touches a pattern used across the codebase
- **Risk-reviewer** — skip unless the change is in a sensitive area (even if file count is small)
- **Context anchor** — skip (single-step tasks do not need drift prevention)

For Small tasks, the following remain required but may be **simplified**:

- **Mandatory deliverable structure** (5 sections: Proposal, Alternatives, Pros/Cons, Risks, Recommendation) — keep it concise; do not skip it
- **Structured preamble** — may be inline (1–2 sentences) rather than a separate section

The following steps **remain mandatory** even for Small tasks:

- **Codebase discovery** — at minimum, read the file being changed and its direct dependents
- **DECISIONS.md check** — verify no contradiction with existing decisions
- **Validation loop** — run at least the targeted tests for the changed file
- **Error recovery** — follow the standard protocol if tests fail
- **Security check** — do not skip even for trivial-looking changes in sensitive areas

### Medium tasks — full workflow

Follow all mandatory steps and workflows as defined in `docs/agent-playbook.md`. Use the existing routing rules to determine which agents are needed.

### Large tasks — full workflow with enhanced rigor

Follow all mandatory steps. Additionally:

- **Planning is mandatory** — use the `feature-planner` agent
- **Critic is mandatory** — invoke after planning, before user approval
- **Risk-reviewer is mandatory** — at minimum for plan assessment; ideally also for final review
- **Context anchor is mandatory** — update before each major step
- **Mid-implementation checkpoint** — pause after each logical group of changes for user review

## Scale labeling

Include the scale classification in your output so humans reviewing the work can quickly understand which path was taken:

- In agent output: include `[SCALE: SMALL]`, `[SCALE: MEDIUM]`, or `[SCALE: LARGE]` near the top
- In commit messages (if applicable): prefix with `[small]`, `[medium]`, or `[large]`

## Project-specific overrides

Teams may customize the Small/Medium/Large thresholds in `docs/operating-rules.md` → `Project-specific constraints`. For example:

- A security-focused project might define: "All changes default to Medium minimum"
- A documentation-only repo might define: "Single-file doc changes are always Small"
- A team might adjust: "Small threshold is 2 files instead of 1"

If project-specific overrides exist, they take precedence over the defaults above.

## Reclassification

If during implementation you discover the task is larger than initially classified (e.g., a "Small" fix actually requires cross-module changes), **stop and reclassify**. If the new classification is higher, switch to the appropriate workflow path. If switching from Small to Medium/Large, this counts as scope expansion and requires user approval per the checkpoint gates.

## Use this skill when

- Starting any new task (after codebase discovery)
- Receiving a request and needing to decide how much process is appropriate
- A task in progress turns out to be larger or smaller than expected

## Conformance self-check

Before proceeding with the classified scale, verify:

- [ ] Classification is based on evidence from codebase discovery (files read), not request text alone
- [ ] Hard blockers were checked: auth, security, schema migration, breaking changes force non-Small
- [ ] If classification was uncertain, Medium was used as default (not Small)
- [ ] The output includes `[SCALE: ...]`, reason, and files affected
- [ ] If reclassifying mid-task (scope grew), the scale was updated and scope expansion approval was requested if moving from Small to Medium/Large
