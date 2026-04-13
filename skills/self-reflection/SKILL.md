---
name: self-reflection
description: Use after producing a deliverable and before handoff to run a fixed-rubric self-critique and revise cycle. Reduces hallucination and drift.
---

# Self-Reflection

Use this skill to validate your own output before emitting a deliverable or handing off to another role. This is an **intra-role** behavior — each role critiques its own work using a fixed rubric, then revises before finalizing.

This is distinct from the `critic` role, which is an **inter-role** mechanism where one agent challenges another agent's plan.

## When to run

Run self-reflection **after** producing a draft deliverable and **before** emitting the final output or handoff artifact. This applies to every role that produces structured output (plans, implementations, reviews, documentation).

### Scale-based adaptation

| Scale | Required rubric dimensions | Max revision rounds |
|-------|---------------------------|---------------------|
| Small | Correctness + Adherence (2 of 5) | 1 |
| Medium | All 5 dimensions | 1 |
| Large | All 5 dimensions | 2 |

## Rubric

Evaluate your draft output against these four dimensions. For each, state **pass** or **fail + specific issue**.

### 1. Correctness

- Is the output logically sound?
- Does the code compile / would the plan work if executed?
- Are there factual errors, hallucinated APIs, or invented file paths?
- Do referenced files, functions, and interfaces actually exist in the codebase?

### 2. Consistency with DECISIONS.md

- Does the output contradict any existing decision in `DECISIONS.md`?
- If it introduces a new pattern, is that acknowledged and justified?
- Are constraint references accurate (not paraphrased incorrectly)?

### 3. Adherence to operating-rules

- Does the output follow the mandatory deliverable structure?
- Are trust-level gates respected?
- Are safety rails followed (no secrets, no unauthorized destructive actions)?
- Is the scope within what was requested (no silent expansion)?

### 4. Completeness

- Are all mandatory sections present (not silently omitted)?
- Are edge cases acknowledged (at minimum as "N/A — [reason]")?
- For plans: are implementation order, test plan, and risk assessment included?
- For code: are validation steps defined?

### 5. Isolation (Medium/Large only)

- Was the current deliverable produced within a single role context?
- If multiple roles contributed, did each run in a separate invocation with handoff artifacts?
- If role-switching occurred within a single context, is it an intentional relaxation (e.g., Medium task at `semi-auto`) or an unintended violation?
- For Small tasks: skip this dimension (single-role tasks do not need isolation checks).

## Reflection output format

After evaluating, produce a brief reflection block (do not omit even if all pass):

```text
## Self-reflection
- Correctness: [pass | fail — description]
- Consistency: [pass | fail — description]
- Adherence: [pass | fail — description]
- Completeness: [pass | fail — description]
- Isolation: [pass | fail | skipped — description]
- Revisions made: [list of changes, or "None"]
```

## Revision protocol

1. If any dimension is **fail**, revise the draft to fix the specific issue before emitting.
2. After revision, re-evaluate only the failed dimensions (not all four).
3. If a dimension still fails after the maximum revision rounds, **emit the output anyway** but include the unresolved issue in the reflection block and flag it as an open risk in the deliverable.

Do not enter an infinite revision loop. The maximum rounds are defined by task scale (see table above).

## Integration with handoff

When this skill produces a reflection result, include it in the handoff artifact under the `reflection_result` field (if using the structured handoff schema) or as an appendix to the text-based handoff artifact.

## Anti-patterns

- **Skipping reflection on Small tasks**: Small tasks still require Correctness + Adherence checks. Only the depth is reduced, not the step itself.
- **Reflection as filler**: Do not produce a generic "all pass" without actually checking. Each dimension must reference specific aspects of the output.
- **Revision scope creep**: Revisions fix the specific failed dimension only. Do not use reflection as an excuse to refactor or expand scope.
