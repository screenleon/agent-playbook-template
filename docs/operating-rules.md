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

When one agent's work feeds into the next, pass a **structured handoff artifact** — not raw conversation history. Include: task, deliverable, key decisions (with DECISIONS.md refs), open risks, constraints for next step, and attached output. See `docs/agent-templates.md` → Handoff artifact template for the full format.

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

When stopping for approval, present: gate name, current state, proposal, risks, and decision needed. See `docs/agent-templates.md` → Checkpoint template for the full format. Never silently skip a mandatory checkpoint.

## Autonomous execution mode

When `execution_mode: autonomous` is declared in `prompt-budget.yml` (or an equivalent project configuration file), agents substitute logged auto-proceed for the human wait states at most checkpoint gates.

**This mode is explicitly opt-in.** The default is `supervised`. Never infer autonomous mode from context — it must be declared in configuration.

### When to use autonomous mode

Autonomous mode is appropriate for:

- CI/CD pipelines and unattended batch workflows where no human is available to approve steps
- Prototyping environments where iteration speed outweighs manual review overhead
- Teams that have validated agent judgment on a given codebase and accept fully automated decisions
- Scripted or integration-test tasks with a well-defined scope and no destructive actions

Do not use autonomous mode for tasks involving schema migrations on production data, permission or security model changes, payment or billing logic, deletion of user data, or any operation that cannot be safely reverted.

### Checkpoint gate behavior in autonomous mode

| Gate | Supervised behavior | Autonomous behavior |
|------|---------------------|---------------------|
| 1. Plan approval | STOP — wait for "PROCEED" | Log plan to `DECISIONS.md`, then auto-proceed |
| 2. Destructive / irreversible actions | STOP — wait | **Always stop. Not bypassable.** |
| 3. Scope expansion | STOP — present expanded scope | If expansion is within original intent: log and proceed. If unrelated module added: stop. |
| 4. Stuck escalation (3 fails) | STOP — report | **Always stop. Not bypassable.** |
| 5. Mid-implementation review | Recommended stop | Skip |
| 6. Before final merge | Recommended stop | Skip |

### Non-bypassable rules in autonomous mode

Even with `execution_mode: autonomous`, the following remain hard stops:

- **Contradiction with `DECISIONS.md`** — never auto-resolve a contradiction. Stop and present the conflict with options. Proceeding autonomously on a known contradiction violates the decision log contract. This rule has no configuration override.

The rules below are enforced by default and **strongly recommended** to keep enabled. They can be relaxed in `prompt-budget.yml` under `autonomous_mode` only for fully isolated or sandboxed environments where the corresponding risk is explicitly accepted:

- **Destructive or irreversible actions** (gate 2) — deleting files, dropping tables, force-pushing, resetting branches, modifying shared infrastructure. Controlled by `halt_on_destructive_actions`. Keep `true` unless the environment is fully sandboxed.
- **Stuck escalation after 3 failed attempts** (gate 4) — agents must not loop forever. Stop and report. Controlled by `halt_on_stuck_escalation`. Keep `true` unless an external timeout mechanism is in place.
- **Severity-high findings from `risk-reviewer`** — any severity-high risk outcome is a hard stop by default. Do not auto-proceed on a severity-high finding; stop and present the finding for user review. Controlled by `halt_on_high_severity_risk`.

### Mandatory audit log in autonomous mode

Every gate that is auto-proceeded must be recorded. Append to `DECISIONS.md` using the standard format, adding one extra field:

```markdown
## YYYY-MM-DD: [Decision title]
- **Context**: Why this decision was needed
- **Decision**: What was decided
- **Alternatives considered**: What was rejected and why
- **Constraints introduced**: What future work must respect
- **Execution mode**: Autonomous — auto-proceeded without user confirmation
```

This preserves the audit trail that a human checkpoint would otherwise provide. Without this log entry, autonomous decisions are invisible to future agents and reviewers.

### Critic behavior in autonomous mode

By default, the `critic` role still runs in autonomous mode. Adversarial challenge benefits implementation quality even without a human reviewing the critique before proceeding.

When there is no human decision step, the critic's output is embedded in the plan handoff artifact. Implementation agents must address each critique point before starting work. Unaddressed critique points must be explicitly recorded as accepted risks in the handoff artifact.

To skip the critic, set `skip_critic_role: true` under `autonomous_mode` in `prompt-budget.yml`. Only do this for tasks with very limited scope where over-engineering risk is negligible.

### Risk-reviewer behavior in autonomous mode

The `risk-reviewer` role always runs after implementation in autonomous mode. Its findings are recorded in the task completion summary. If the risk-reviewer identifies a severity-high finding, the agent must stop and report — even in autonomous mode. Severity-medium and lower findings are logged and accepted.

### Autonomous mode is not "skip planning"

Autonomous mode removes the **human wait states**, not the **work steps**. The agent still:

- Discovers the codebase before coding
- Classifies task scale with demand-triage
- Produces a plan (feature-planner still runs)
- Runs the critic
- Validates with the test-and-fix loop
- Records decisions in `DECISIONS.md`

The only difference is that the agent proceeds through these steps automatically instead of pausing for user "PROCEED" signals.

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

At the start of every long task (more than one step or more than one file), produce a context summary with: objective, current step, completed items, remaining items, and active constraints. Update before each major step. See `docs/agent-templates.md` → Context anchor template for the format.

### Context compaction

Long tasks cause context growth that increases cost and reduces model accuracy. To prevent this:

- After completing each phase of a multi-phase task, produce a progress summary and store it in session memory (see `skills/memory-and-state/SKILL.md` → Context compaction protocol).
- Continue subsequent work from the summary, not from the full conversation history.
- For inter-agent handoffs, the compaction summary becomes the handoff artifact defined in the Context isolation section above.
- If a tool or agent session does not support explicit compaction, produce the summary in the output and instruct the next step to use it as primary input.

### Instruction loading order

Load instruction content in layer order: static rules → stable skills → project state → volatile context. Never reorder layers; never inject per-request content into the static or skill layers. See `skills/prompt-cache-optimization/SKILL.md` for the full four-layer model, canonical skill sets, provider-specific notes, and file size guidelines.

### Output completeness check

After producing structured output (plans, reviews, checklists), agents must verify:

- Every item in the required checklist has been addressed (not skipped)
- The output format matches the template (section headers, required fields)
- No required section was silently omitted

If a section is not applicable, write "N/A — [reason]" instead of omitting it.

### Mandatory deliverable structure

Every agent role must produce its final output using the Deliverable template in `docs/agent-templates.md`. The five required sections are: Proposal, Alternatives considered, Pros/Cons, Risks, Recommendation. Roles may add domain-specific sections but must not omit these five. Write "N/A — [reason]" for any section that genuinely does not apply.

### Small-task minimum output contract

Small tasks may simplify depth, but must keep explicit structure. The minimum acceptable output for Small tasks is:

1. Compliance block (from above)
2. Structured preamble (Assumptions, Constraints, Proposed approach; inline allowed)
3. DECISIONS.md contradiction check result
4. Validation plan and targeted verification outcome
5. Mandatory deliverable structure with concise content and explicit `N/A` where applicable

Small tasks must not skip explicit workflow declaration or verification reporting.

## Feedback loop and quality signals

Process quality must be monitored continuously, not only during one-off reviews.

### Task-end mini retrospective (mandatory)

After the mandatory deliverable and task completion summary, add a short feedback block:

1. **Friction observed** — which rule or step was hardest to follow
2. **Miss risk** — which required output was most likely to be skipped
3. **Most useful rule** — which rule prevented drift or rework
4. **Next improvement** — one concrete wording/process improvement candidate

Keep this to 3-6 lines. This is a process signal, not a long narrative.

### Quality signals (tracked over a rolling window)

Track these metrics every 10 tasks (or weekly, whichever comes first):

1. **Compliance-block completeness rate** — percentage of tasks with all required first-response fields
2. **Small-path explicitness rate** — percentage of Small tasks that include validation reporting and contradiction-check output
3. **Scope-expansion reclassification rate** — percentage of tasks reclassified upward after implementation starts

Record results in a concise note (for example in session/repo memory or a team tracking doc).

### Escalation rule for recurring friction

If the same process failure appears 3 times in the rolling window:

1. Update source-of-truth wording (`docs/operating-rules.md` and/or `docs/agent-playbook.md`)
2. Synchronize tool-specific files (`.github/copilot-instructions.md`, relevant skills)
3. Add a `CHANGELOG.md` entry describing the process correction

Do not rely on ad-hoc reminders once recurrence is detected.

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

### Decision archive lifecycle

When `DECISIONS.md` exceeds 50 entries or 30 KB, or when any memory health indicator reaches the "needs attention" threshold, archive inactive decisions to `DECISIONS_ARCHIVE.md`. See `skills/memory-and-state/SKILL.md` → Memory lifecycle management for the full procedure, safety checks, and health indicators.

Key rules:
- Archive only entries whose constraints are no longer enforced by current code
- Never archive based on date alone
- Each archived entry must include the reason it was archived
- Agents read `DECISIONS.md` by default; read archive only when working with legacy modules or when contradiction detection finds no match in active decisions

### Mandatory read-before-write

Before making any architectural or behavioral decision, agents **must**:

1. Read `DECISIONS.md` in full
2. If the task involves legacy code or historical migrations, search `DECISIONS_ARCHIVE.md` for related prior decisions if the archive file exists
3. Check whether the proposed change contradicts any relevant decision found in the active log or archive search results
4. If it contradicts: stop and present the contradiction to the user with both the existing decision and the proposed change. Do not silently override.

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

```markdown
## Contradiction detected
- **Existing decision**: [date and title from DECISIONS.md]
- **Proposed change**: [what the current task wants to do]
- **Conflict**: [why these are incompatible]
- **Options**: (a) follow existing decision, (b) reverse existing decision with justification

Waiting for user decision before proceeding.
```

This is a mandatory checkpoint — do not resolve contradictions autonomously.
