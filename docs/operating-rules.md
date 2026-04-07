# Operating Rules

This file is the source of truth for safety, scope control, validation, destructive-action rules, codebase discovery, error recovery, and project-specific constraints.

## Safety rails

- Never expose secrets, tokens, private keys, or credentials in code, logs, screenshots, or documentation.
- Never perform destructive actions without explicit user approval when the tool or environment does not already enforce approval.
- Treat branch protections, review requirements, and deployment safeguards as hard constraints, not suggestions.
- Prefer the minimum required permissions, scope, and file changes.

## Scope control

- Do not expand the task beyond the requested outcome without stating why.
- If a task is ambiguous, reduce ambiguity first through planning instead of guessing across multiple modules.
- Keep fixes local unless the broader change is necessary for correctness.

## Human checkpoint gates

Agents must **STOP and wait for explicit user approval** at these points. Do not proceed automatically.

### Mandatory checkpoints

1. **Plan approval** — after the planning agent produces a plan, present it to the user and wait for "PROCEED" or revision before any implementation starts.
2. **Destructive or irreversible actions** — before deleting files, dropping tables, force-pushing, resetting branches, or modifying shared infrastructure.
3. **Scope expansion** — if work reveals that more modules, contracts, or schemas need to change than originally planned, stop and present the expanded scope for approval.
4. **Stuck escalation** — after 3 failed attempts at the same error, stop and report instead of continuing to guess.

### Recommended checkpoints

5. **Mid-implementation review** — for tasks with more than 5 files changed, pause after completing the first logical group and present progress before continuing.
6. **Before final merge** — present a summary of all changes for user review before marking work as complete.

### Checkpoint format

When stopping for approval, present:

```
## Checkpoint: [gate name]

**Current state**: [what has been done so far]
**Proposal**: [what will happen next]
**Risks**: [what could go wrong]
**Decision needed**: [specific yes/no or choice the user must make]

Waiting for approval before proceeding.
```

Never silently skip a mandatory checkpoint. If a tool does not support interactive approval, write the checkpoint to the output and stop.

## Codebase discovery (repo-aware)

Before writing or modifying any code, perform these steps:

1. **Read related files** — identify and read the files that will be changed and their direct dependents. Do not guess file contents.
2. **Identify existing patterns** — look for naming conventions, folder structure, error handling style, logging patterns, and test conventions already in use.
3. **Follow repository conventions** — match the existing code style, framework idioms, and architectural patterns. Do not introduce a new pattern when an established one exists.
4. **Check dependency graph** — understand imports, module boundaries, and shared types before making cross-file changes.
5. **Read project-specific constraints** — check the `Project-specific constraints` section below and any `CONVENTIONS.md`, `ARCHITECTURE.md`, or similar files at the repo root.

If you skip discovery, state what you skipped and why.

## Validation loop (write → test → fix → repeat)

After every code change, follow this mandatory loop:

1. **Run tests** — execute the project's test suite (e.g., `go test ./...`, `npm test`, `pytest`, `mvn test`). Run the most targeted subset first, then broaden if needed.
2. **Run static analysis** — execute linters and type checkers (e.g., `go vet`, `eslint`, `mypy`, `cargo clippy`).
3. **Check for errors** — if tests or analysis fail, do not move on. Go to the error recovery section.
4. **Repeat** — continue the loop until all tests pass and no new warnings are introduced.
5. **Report** — if the loop cannot converge after 3 attempts, stop and report the remaining failures to the user.

Never treat a change as complete until verification passes. If the project has no test suite, state that explicitly and describe what manual verification was done or is still needed.

## Structured output and anti-drift

Long tasks cause agents to forget instructions, skip format requirements, and drift from the original objective. These rules prevent that.

### Mandatory chain-of-thought (CoT)

Before producing any solution or implementation, agents must explicitly state:

1. **Assumptions** — what is being assumed about the request, codebase, or constraints
2. **Constraints** — what limits apply (from `DECISIONS.md`, project-specific constraints, or the request itself)
3. **Proposed approach** — the logic or steps before writing code

This must appear in the output before any code or implementation. Skipping this step is not allowed.

### Context anchor

At the start of every long task (more than one step or more than one file), agents must produce a context summary:

```
## Context anchor
- **Objective**: [what we are trying to achieve]
- **Current step**: [which step we are on, e.g., "3 of 7"]
- **Completed so far**: [brief list of what is done]
- **Remaining**: [brief list of what is left]
- **Active constraints**: [key constraints from DECISIONS.md or project rules]
```

Update this anchor before each major step. This prevents drift by forcing the agent to re-read the plan.

### Output completeness check

After producing structured output (plans, reviews, checklists), agents must verify:

- Every item in the required checklist has been addressed (not skipped)
- The output format matches the template (section headers, required fields)
- No required section was silently omitted

If a section is not applicable, write "N/A — [reason]" instead of omitting it.

## Error recovery

When you encounter a compile error, test failure, or unexpected runtime behavior:

1. **Read the full error message** — do not guess from partial output.
2. **Identify the root cause** — trace the error to the specific file, line, and logical mistake.
3. **Fix the minimal code** — change only what is needed to resolve the error. Do not refactor unrelated code during error recovery.
4. **Re-run verification** — go back to the validation loop.
5. **Escalate if stuck** — if the same error persists after 3 fix attempts, report it to the user with: the error message, what you tried, and what you think the underlying issue is.

Do not silently ignore errors. Do not remove failing tests to make the suite pass.

## Review expectations

- High-risk work should pass through a reviewer role before being considered complete.
- Findings should be prioritized by severity, then by likelihood of causing user-visible or operational failure.
- Documentation changes should be reviewed for factual correctness and consistency with the current workflow.

## Tool usage boundaries

- Use tool-specific implementations only as surfaces for the same conceptual roles.
- If a tool does not support named subagents, use the equivalent prompt template or local instruction file instead.
- Do not assume one vendor-specific feature exists in another tool.

## Project-specific constraints

<!-- Teams MUST fill this section when adopting the template. -->
<!-- Examples of concrete constraints: -->
<!-- - Use raw SQL with sqlc; no ORM -->
<!-- - Do not modify the DB schema without a migration file -->
<!-- - Pricing logic must use JSONB rule definitions -->
<!-- - All HTTP handlers must use the shared middleware stack -->
<!-- - Authentication uses JWT with RS256; do not switch algorithms -->
<!-- - Frontend state management uses Zustand; do not introduce Redux -->

_This section is intentionally blank in the template. Fill it with your repository's actual technical constraints, architectural decisions, and non-negotiable patterns._

## Decision log

Maintain a `DECISIONS.md` file (or equivalent) at the repository root to record:

- **What** was decided
- **Why** the decision was made (alternatives considered)
- **When** it was decided
- **Constraints** it introduces for future work

Agents should read this file during codebase discovery and append to it when making architectural or behavioral decisions that future work depends on.

### Mandatory read-before-write

Before making any architectural or behavioral decision, agents **must**:

1. Read `DECISIONS.md` in full
2. Check whether the proposed change contradicts an existing decision
3. If it contradicts: stop and present the contradiction to the user with both the existing decision and the proposed change. Do not silently override.

### Automatic decision capture

After any of these events, agents must append a new entry to `DECISIONS.md`:

- A new technology, library, or pattern is introduced
- A schema or contract is changed
- A permission or security model is modified
- An architectural boundary is created or moved
- A tradeoff is made (performance vs. readability, scope vs. timeline, etc.)

Use this format:

```markdown
## YYYY-MM-DD: [Decision title]
- **Context**: Why this decision was needed
- **Decision**: What was decided
- **Alternatives considered**: What was rejected and why
- **Constraints introduced**: What future work must respect
```

### Contradiction detection

If an agent discovers that a proposed change conflicts with an existing entry in `DECISIONS.md`:

```
## Contradiction detected
- **Existing decision**: [date and title from DECISIONS.md]
- **Proposed change**: [what the current task wants to do]
- **Conflict**: [why these are incompatible]
- **Options**: (a) follow existing decision, (b) reverse existing decision with justification

Waiting for user decision before proceeding.
```

This is a mandatory checkpoint — do not resolve contradictions autonomously.
