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

## Context isolation

Roles sharing a single conversation context will eventually drift, contaminate each other's state, and lose control on long tasks. Prevent this by isolating contexts.

### Task boundary rule

Each conceptual role (planner, architect, implementer, critic, reviewer) should run as a **separate agent invocation** with its own context. Do not switch roles within one long conversation.

- One task = one agent = one context.
- If a tool supports named subagents or new sessions, use them.
- If a tool only supports a single conversation, insert a **hard context break** between roles: summarize the previous role's output into a structured handoff artifact, then begin the next role with only that artifact as input.

### Handoff artifact

When one agent's work feeds into the next, pass a **structured handoff artifact** — not raw conversation history. The handoff artifact must contain:

```
## Handoff: [source role] → [target role]
- **Task**: [one-sentence objective]
- **Deliverable**: [what the source role produced]
- **Key decisions**: [decisions made, with references to DECISIONS.md entries]
- **Open risks**: [unresolved risks or questions]
- **Constraints for next step**: [what the target role must respect]
- **Attached output**: [the actual plan, review, or implementation summary]
```

### Anti-patterns (banned)

- **Role ping-pong** — switching roles back and forth in the same context more than once. If you need a second opinion, spawn a new context.
- **Implicit handoff** — continuing from one role to the next without an explicit handoff artifact. The next agent must not rely on "what was said earlier."
- **Conversation-as-memory** — using scroll-back or prior messages as the source of truth. Use `DECISIONS.md`, handoff artifacts, and context anchors instead.

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

### Mandatory structured preamble

Before producing any solution or implementation, agents must explicitly provide a brief, high-level summary of:

1. **Assumptions** — what is being assumed about the request, codebase, or constraints
2. **Constraints** — what limits apply (from `DECISIONS.md`, project-specific constraints, or the request itself)
3. **Proposed approach** — a short, high-level summary of the intended approach without detailed step-by-step reasoning

This must appear in the output before any code or implementation. Do not require or provide detailed internal reasoning.

### Mandatory first-response compliance block

The first response of any implementation task must include a visible compliance block so users can verify process adherence.

Required fields:

1. **Read set** — list the files/rules read before implementation
2. **Scale** — `[SCALE: SMALL|MEDIUM|LARGE]` and evidence-based reason
3. **Workflow path** — Small simplification path or Medium/Large planning path, with justification
4. **Checkpoint map** — mandatory checkpoints that will be used in this task (or `N/A` with reason)

If this block is missing, the workflow is considered not started.

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

### Context compaction

Long tasks cause context growth that increases cost and reduces model accuracy. To prevent this:

- After completing each phase of a multi-phase task, produce a progress summary and store it in session memory (see `skills/memory-and-state/SKILL.md` → Context compaction protocol).
- Continue subsequent work from the summary, not from the full conversation history.
- For inter-agent handoffs, the compaction summary becomes the handoff artifact defined in the Context isolation section above.
- If a tool or agent session does not support explicit compaction, produce the summary in the output and instruct the next step to use it as primary input.

### Output completeness check

After producing structured output (plans, reviews, checklists), agents must verify:

- Every item in the required checklist has been addressed (not skipped)
- The output format matches the template (section headers, required fields)
- No required section was silently omitted

If a section is not applicable, write "N/A — [reason]" instead of omitting it.

### Mandatory deliverable structure

Every agent role must produce its final output in this standardized format. This prevents freeform drift and ensures decision-quality information reaches the user.

```
## Deliverable: [title]

### Proposal
[What is being proposed — the solution, plan, or finding]

### Alternatives considered
[At least one alternative approach and why it was not chosen]

### Pros / Cons
| Pros | Cons |
|------|------|
| ...  | ...  |

### Risks
[Each risk with likelihood, impact, and mitigation — or "None identified"]

### Recommendation
[Clear, actionable recommendation for the user or the next agent]
```

Roles may add domain-specific sections (e.g., a planner adds "implementation order," a reviewer adds "findings"), but the five sections above are mandatory and must not be omitted. Write "N/A — [reason]" for any section that genuinely does not apply.

### Small-task minimum output contract

Small tasks may simplify depth, but must keep explicit structure. The minimum acceptable output for Small tasks is:

1. Compliance block (from above)
2. Structured preamble (Assumptions, Constraints, Proposed approach; inline allowed)
3. DECISIONS.md contradiction check result
4. Validation plan and targeted verification outcome
5. Mandatory deliverable structure with concise content and explicit `N/A` where applicable

Small tasks must not skip explicit workflow declaration or verification reporting.

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

## Workflow synchronization guardrail

When updating workflow stage names or order (for example the loop sequence), keep all canonical references synchronized in the same change.

Minimum sync targets:

- `AGENTS.md` loop string and numbered flow breakdown
- `docs/agent-playbook.md` three-layer loop summary and mandatory steps section
- `.github/copilot-instructions.md` mandatory workflow steps
- `skills/demand-triage/SKILL.md` Small-path requirements
- `CHANGELOG.md` entry describing the workflow update

Do not leave stale stage names (for example `Read` as a standalone stage after switching to `Discover`) in any of these files.

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
