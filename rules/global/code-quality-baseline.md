# Code Quality Baseline

Global rules that govern individual coding behavior across all projects and domains.
These rules address the most common failure modes observed in LLM-assisted coding:
silent assumption-making, speculative over-building, and unintended side-effect changes.

> **Relationship to `docs/operating-rules.md`**: These rules complement — and do not
> replace — the procedural rules in `docs/operating-rules.md`. Load and read both
> files before proceeding. These rules govern *what* to build and *how* to approach
> scope (coding mindset). `docs/operating-rules.md` governs *how* to structure the
> workflow (checkpoints, validation, output format, trust levels). When both address
> the same topic, `docs/operating-rules.md` takes precedence for procedural detail;
> these rules take precedence for coding-scope judgments.
>
> Cross-references: GCODE-001 ↔ Scope control; GCODE-002 ↔ Mandatory structured
> preamble; GCODE-004 ↔ TDAI requirement and Validation loop.

## Rules

### Rule: GCODE-001

- Owner layer: Global
- Scope: all code generation and modification tasks
- Stability: behavior
- Status: active
- Directive: Implement only the functionality that was explicitly requested. Do not add speculative features, optional configuration knobs, single-use abstractions, helper utilities, or error handling for scenarios that cannot realistically occur in the current context.
- Rationale: LLM-generated code consistently over-builds. Each unrequested addition increases review surface, introduces untested paths, and signals that the agent did not understand the bounded scope of the task.
- Conflict handling: If a requested feature genuinely requires an abstraction or helper to be correct, build it — but state why in the structured preamble. Domain or project rules may define approved patterns that expand what counts as "requested." See also `docs/operating-rules.md` → Scope control for the procedural complement to this rule.
- Example: Asked to add a `POST /users` endpoint → implement that endpoint only. Do not add pagination, a generic CRUD base class, or a soft-delete flag "for future use."
- Non-example: Asked to rename a function → also refactor the surrounding logic, extract a utility, and add a new config option for "flexibility."

### Rule: GCODE-002

- Owner layer: Global
- Scope: all tasks before implementation begins
- Stability: behavior
- Status: active
- Directive: Before writing any code, state assumptions explicitly. When the request is ambiguous or contains an unresolvable confusion point, stop, name the ambiguity, and ask for clarification. When multiple valid interpretations exist, present them and wait for a choice rather than silently selecting one.
- Rationale: Silent assumption-making is the root cause of most large wasted-effort rewrites. A clarification question costs seconds; a wrong implementation costs minutes to hours. Surfacing confusion before coding prevents divergence from user intent.
- Conflict handling: The structured preamble (see `docs/operating-rules.md` → Mandatory structured preamble) is the canonical surface for stating assumptions. If a task is clearly unambiguous, the preamble may be brief — but never empty. For trust-level-specific gate behavior (including autonomous mode), see `docs/operating-rules.md` → Trust level. Autonomous mode modifies when and whether to pause for user input; it does not remove the requirement to state assumptions.
- Example: Asked to "optimize the query" → present two interpretations (reduce latency vs. reduce database load) with the tradeoff, and ask which goal the user has in mind before touching any code.
- Non-example: Asked to "fix the bug in the login flow" → silently pick the most likely fix and implement it without stating what was assumed about the bug's root cause.

### Rule: GCODE-004

- Owner layer: Global
- Scope: all tasks before implementation begins, and after each implementation step
- Stability: behavior
- Status: active
- Directive: Before starting work, convert the request into at least one concrete, verifiable success criterion. For multi-step tasks, define a checkpoint and verification step for each phase. After each implementation step, verify against the stated criterion before moving on or declaring the task complete.
- Rationale: Abstract task definitions ("improve the performance," "make it cleaner") have no completion boundary, which causes agents to either over-build or under-deliver. Explicit success criteria enable independent verification loops and prevent scope drift.
- Conflict handling: For Small tasks at `semi-auto` or `autonomous` trust level, the success criterion may be a single inline statement rather than a formal plan. For Large tasks, the criterion should be recorded in the structured preamble and validated at each checkpoint gate. See `docs/operating-rules.md` → TDAI requirement and Validation loop for the procedural complement to this rule.
- Example: Asked to "speed up the test suite" → state the criterion ("test suite must run in under 30 seconds on CI; current baseline is 90 seconds") before touching any code. Verify after each change.
- Non-example: Start optimizing without defining what "fast enough" means, and stop only when the work "feels done."
