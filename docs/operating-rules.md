# Operating Rules

This file is the source of truth for safety, scope control, validation, destructive-action rules, codebase discovery, error recovery, and project-specific constraints.

## Agent-deference principle

This template is designed to complement — not replace — the capabilities that agent tools already provide natively.

**Rule: prefer the agent's built-in behavior first.** Only apply template-level rules when the agent tool does not already cover the capability.

Examples of behaviors typically handled by the agent tool (do not re-specify):

- Confirmation prompts before destructive terminal commands (most agent tools enforce this)
- File-read and search tool selection (the agent's own toolchain handles this)
- Basic code-style formatting (handled by linters and the agent's native conventions)
- Token management and context-window limits (handled by the agent runtime)
- Concrete provider/model selection mechanics and model IDs (keep them in the tool runtime, adapter config, or local overrides)

Examples of behaviors this template adds because agents lack them:

- Project-specific decision log (`DECISIONS.md`) and contradiction checks
- Role routing and multi-agent coordination workflows
- Scale-based workflow adaptation (demand triage)
- Repository-specific conventions and architectural constraints
- Structured handoff artifacts between agent invocations
- Optional abstract model-tier routing intent when a project needs vendor-neutral policy across runtimes

When adopting this template, review each rule section and mark items already covered by your agent tool as `[AGENT-NATIVE]`. Those items can be trimmed from the project-level instructions to reduce token overhead. See `docs/adoption-guide.md` for the full trimming process.

## Trust level

This template supports three trust levels that control how much human approval is required. The canonical project configuration surface is `prompt-budget.yml` → `execution_mode`; tools that do not use `prompt-budget.yml` may map the same three values through equivalent local settings.

| Level | Description | When to use |
|---|---|---|
| `supervised` | All mandatory checkpoints require human approval. Full compliance output on every task. | High-risk projects, unfamiliar codebases, onboarding new agents |
| `semi-auto` (default) | Small and low-risk Medium tasks run autonomously. Checkpoints activate only for Large, high-risk, or destructive work. | Most development work |
| `autonomous` | Agent proceeds without human approval except for irreversible/destructive actions. | Trusted repos with good test coverage and branch protections |

### How trust level interacts with checkpoints

- **Destructive actions** (delete files, drop tables, force-push): always require human approval at `supervised` and `semi-auto`. In `autonomous`, stop by default unless `autonomous_mode.halt_on_destructive_actions: false` is explicitly configured.
- **Plan approval**: required at `supervised`; required for Large or high-risk work at `semi-auto`; ADVISORY by default at `autonomous`, and may remain STOP behavior when `autonomous_mode.auto_proceed_on_plan: false` is configured.
- **Scope expansion**: required at `supervised` and `semi-auto`; ADVISORY at `autonomous`.
- **Stuck escalation** (3 failed attempts): requires human escalation by default. In `autonomous`, it may continue only when `autonomous_mode.halt_on_stuck_escalation: false` is explicitly configured.

### Setting the trust level

Prefer setting the trust level in `prompt-budget.yml`:

```yaml
execution_mode: semi-auto  # supervised | semi-auto | autonomous
```

If your agent does not read `prompt-budget.yml`, map the same three values through the tool's equivalent local setting. If not specified, `semi-auto` is the default.

### Autonomous gate overrides

Users who understand the risks and want more unattended execution can tune gate behavior under `prompt-budget.yml` → `autonomous_mode`.

```yaml
execution_mode: autonomous
autonomous_mode:
  halt_on_destructive_actions: true
  halt_on_stuck_escalation: true
  skip_critic_role: false
```

Changing these flags reduces human stops in autonomous mode, but does not override constitutional principles or `DECISIONS.md` contradiction stops.

**Use only when you accept responsibility for the corresponding risk tradeoffs.** Recommended safeguards before enabling looser autonomous behavior:

- Working on a non-production branch
- A recent checkpoint or backup exists
- CI/CD or branch protections provide a downstream safety net
- The scope of the task is well-defined and bounded

These flags have no effect unless `execution_mode` is `autonomous`. They do not override security rules (no secrets in code, no credential exposure).

## Abstract model-tier routing (optional)

Some teams control model selection in their runtime or orchestration layer; others do not. To keep this template portable, any model-routing policy in tracked repository files must stay **abstract and vendor-neutral**.

Use `prompt-budget.yml` → `model_routing` only when your runtime actually exposes model selection. That section may define abstract tiers such as `fast`, `balanced`, and `deep`, along with escalation triggers and non-goals. Keep concrete provider/model IDs in adapter config, `prompt-budget.local.yml`, or runtime settings instead of source-of-truth docs.

Important boundary: **tier escalation is runtime-local retry policy for the same role/task**. It does not replace trust-level checkpoints, role handoffs, or the default stuck-escalation stop after 3 failed attempts.

If your tool chooses models automatically or hides model selection completely, omit `model_routing` and rely on the tool's native behavior.

## Constitutional principles

These principles are **non-bypassable**. No trust level, autonomous-mode override, project-specific constraint, or override annotation can weaken or skip them. They represent the absolute floor of agent behavior.

1. **Never expose credentials** — never output secrets, tokens, private keys, API keys, or credentials in code, logs, screenshots, documentation, trace files, or any other artifact.
2. **Never execute unvalidated input as code** — never run user-supplied or externally-sourced input as executable code without sandboxing or explicit validation. This includes `eval()`, dynamic SQL, shell injection vectors, and template injection.
3. **Never modify production data without backup verification** — before any write operation against production data stores, verify that a backup or rollback path exists. If verification is not possible, stop and report.
4. **Never disable authentication or authorization** — never remove, bypass, or weaken auth checks, permission gates, or security middleware, even temporarily, even in test environments that mirror production.
5. **Never suppress security test failures** — never delete, skip, or mark as expected-failure any test that validates security behavior (auth, permissions, input validation, encryption) to make a test suite pass.

Violation of any constitutional principle is a **hard stop** regardless of execution mode. The agent must halt, report the violation, and wait for human resolution.

## Safety rails

In addition to the constitutional principles above, follow these safety rails. Unlike constitutional principles, some rails can be relaxed by specific `autonomous_mode.*` settings where noted.

- Never perform destructive actions without explicit user approval when the tool or environment does not already enforce approval, unless `execution_mode: autonomous` and `autonomous_mode.halt_on_destructive_actions: false` are explicitly configured.
- Treat branch protections, review requirements, and deployment safeguards as hard constraints, not suggestions.
- Prefer the minimum required permissions, scope, and file changes.

## Layered configuration

To keep this template adaptable across repositories, split constraints into three layers.

1. **Global Rules (core layer)** — communication norms, coding style baseline, universal security constraints.
2. **Domain Rules (domain layer)** — domain-specific constraints such as backend API, cloud infrastructure, or frontend component systems.
3. **Project Context (project layer)** — repository-local boundaries and operational constraints.

Reference structure:

- `rules/global/` — core rules
- `rules/domain/` — domain-specific rules
- `project/project-manifest.md` — project-local context template

When the same topic appears in multiple layers, use this precedence order:

1. Project Context
2. Domain Rules
3. Global Rules

### Layer placement rubric

Place each rule in the lowest layer that can safely own it:

1. Put a rule in **Global Rules** only if it should apply to nearly every repository.
2. Put a rule in **Domain Rules** if it is specific to a technical domain but reusable across multiple repositories.
3. Put a rule in **Project Context** if it depends on repository-local constraints, team operations, or legacy compatibility.

If uncertain, default to Domain Rules (not Global Rules) to avoid accidental overreach.

### Resolution algorithm

When multiple rules apply to the same topic, resolve deterministically:

1. Collect candidate rules from Project, Domain, and Global layers.
2. Keep only active rules (ignore deprecated/superseded notes).
3. Apply precedence: Project > Domain > Global.
4. If conflicts remain inside the same layer, prefer the more specific scope (module-specific over repo-wide).
5. If still tied, prefer the most recent dated rule and record the tie-break in `DECISIONS.md`.

### Layer hygiene guardrails

- Avoid duplicate rule text across layers; higher layers should override by reference, not copy-paste.
- Mark superseded rules explicitly to prevent silent ambiguity.
- When moving a rule between layers, update references in `AGENTS.md`, `docs/adoption-guide.md`, and tool-specific instruction files in the same task.

### Workspace boundary masking

When a repository contains multiple modules, workspaces, or service roots, domain rules can be selectively masked so that only the rules relevant to the current working context are active.

#### Defining boundaries

Declare boundaries in `project/project-manifest.md` under the `## Workspace boundaries` section. Each boundary entry maps a glob pattern to the domain rule files that should be **active** within that path:

```markdown
| Path glob | Active domain rules | Masked domain rules |
|---|---|---|
| `services/api/**` | backend-api | frontend-components |
| `packages/ui/**` | frontend-components | backend-api |
| `infra/**` | cloud-infra | backend-api, frontend-components |
```

#### Masking rules

1. **Global rules are never masked.** Boundaries apply only to domain-level rules.
2. When working inside a path that matches a boundary glob, load only the **active** domain rules for that path.
3. If a file does not match any boundary glob, load all domain rules (no masking).
4. When a change spans multiple boundary paths, load the **union** of all active domain rules for the affected paths.
5. Boundaries are advisory — an agent may explicitly load a masked rule when justified, and must record the reason in the handoff artifact or `DECISIONS.md`.

#### Backward compatibility

If `project/project-manifest.md` does not contain a `## Workspace boundaries` section, all domain rules are loaded unconditionally. Existing repositories are unaffected until boundaries are explicitly defined.

### Dynamic spawning guardrails

When a coordinator dynamically spawns sub-roles at runtime (see `docs/agent-playbook.md` → Dynamic orchestration), the following guardrails apply:

1. **Max depth = 3** — the spawn chain (coordinator → sub-role → sub-sub-role) must not exceed 3 levels. Any spawn attempt beyond depth 3 is a **hard stop** — the coordinator must escalate to the user.
2. **No self-delegation** — role A must not spawn role A. Circular spawning is prohibited.
3. **Handoff schema required** — every dynamic spawn must include a handoff artifact conforming to `docs/schemas/handoff-artifact.schema.yaml` with the `orchestration` block populated (`parent_role`, `spawn_depth`, `plan_of_record_ref`).
4. **Idle reclaim** — if a spawned sub-role produces no output after 2 exchange rounds, the coordinator reclaims the task. This prevents stalled delegation chains.
5. **Plan-of-record logging** — the coordinator must update a plan-of-record table before each spawn and after each completion. See `docs/agent-templates.md` → Plan of record.
6. **Trust-level interaction** — dynamic spawning does not bypass trust-level gates. If the spawned work requires a checkpoint (e.g., destructive action), the checkpoint still fires.

## Rule stability classification

Scope layering (Global / Domain / Project) controls **where** a rule applies. Stability classification controls **how carefully** a rule may be changed. These two dimensions are orthogonal — every rule has both a scope layer and a stability level.

### Stability levels

| Level | Meaning | Change process | Rollback |
|---|---|---|---|
| `core` | Defines identity and safety — rarely changes | Requires `risk-reviewer` audit + user approval + `DECISIONS.md` entry | Treated as breaking change |
| `behavior` | Defines how work is done — adjustable with care | Requires validation loop pass + `DECISIONS.md` entry | Normal revert |
| `experimental` | Defines new patterns being tested — freely changeable | Record in `DECISIONS.md` only; no approval gate | Revert at any time |

### How to assign stability

| Question | If yes | If no |
|---|---|---|
| Would changing this rule risk safety, security, or fundamental agent identity? | `core` | next question |
| Would changing this rule alter agent workflow behavior or output quality? | `behavior` | next question |
| Is this rule testing a new pattern, tool usage, or prompt technique? | `experimental` | `behavior` (default) |

If uncertain, default to `behavior`.

### Marking stability in rule entries

Add `- Stability: core | behavior | experimental` to the rule schema alongside existing fields:

```markdown
### Rule: <RULE_ID>
- Owner layer: Domain
- Domain: <domain>
- Stability: behavior
- Status: active
- ...
```

The `scripts/lint-layered-rules.sh` linter validates that every rule entry includes a `Stability` field with a valid value.

### Stability-aware change protocol

- **Changing a `core` rule**: invoke `risk-reviewer` to assess blast radius. Record the change rationale, alternatives considered, and rollback plan in `DECISIONS.md`. At `supervised` and `semi-auto` trust levels, wait for user approval. At `autonomous` trust level, log an ADVISORY and proceed.
- **Changing a `behavior` rule**: run the validation loop to confirm no regression. Record in `DECISIONS.md`.
- **Changing an `experimental` rule**: record in `DECISIONS.md` for traceability. No approval gate required.

## Rule authoring contract

Write reusable rules as contracts, not as free-form narrative.

Every active rule entry should include these minimum fields:

1. `Rule ID`
2. `Owner layer`
3. `Scope`
4. `Stability`
5. `Status`
6. `Directive`
7. `Rationale`
8. `Conflict handling`
9. `Example`
10. `Non-example`

Use this canonical shape:

```markdown
### Rule: <RULE_ID>
- Owner layer: Global | Domain | Project
- Scope: [where this rule applies]
- Stability: core | behavior | experimental
- Status: active | superseded | draft
- Directive: [clear imperative rule]
- Rationale: [why this rule exists]
- Conflict handling: [what overrides this rule or when to escalate]
- Example: [positive example]
- Non-example: [what this rule forbids or does not cover]
```

Incomplete rule entries are not considered stable source-of-truth material. At minimum, `Directive`, `Rationale`, and `Conflict handling` must never be omitted.

## Scope control

- Do not expand the task beyond the requested outcome without stating why.
- If a task is ambiguous, reduce ambiguity first through planning instead of guessing across multiple modules.
- Keep fixes local unless the broader change is necessary for correctness.

## Documentation and framework maintenance

- Keep normative rule text in one canonical owner document. Other surfaces should summarize, point to, or restate it only when they explicitly surface the same rule.
- When the same fact is owned in more than one documentation layer, update each owning document in the same change.
- Sync only the surfaces that explicitly mention the changed rule, workflow term, file path, or command. Do not expand minor wording changes into a repo-wide sweep by default.

## Intent mode

Roles answer **who owns the work**. Intent modes answer **what the current phase is**.

Use these canonical intent modes:

| Intent mode | Primary goal | Default file mutation stance |
|---|---|---|
| `analyze` | Understand current state, scope work, propose changes | read-only |
| `implement` | Apply changes and validate them | edits allowed when the role permits edits |
| `review` | Find bugs, risks, regressions, and gaps | read-only |
| `document` | Update rules, ADRs, runbooks, and supporting docs | docs-only by default |

Intent mode constrains the current step. It does not replace role routing and never expands a role's default capabilities.

Examples:

- A `feature-planner` in `analyze` mode explores and plans, but does not implement.
- An `application-implementer` may start in `analyze` mode, then move to `implement` mode in the same task when the workflow allows it.
- A `risk-reviewer` stays read-only even if a tool labels the session as `implement`.

### Intent mode transition rules

1. For Medium and Large tasks, state the current intent mode in the structured preamble, handoff artifact, or both.
2. A mode switch inside the same role does **not** require a new agent or new context by default.
3. A role switch still follows the Context isolation rules below unless the scale-based relaxation explicitly allows a shared context.
4. Switching from `analyze` to `implement` must restate the intended change scope before edits begin.
5. Switching into `review` mode ends implementation for that pass. Do not keep editing while presenting a final review.
6. If a mode switch expands scope beyond the original intent, trigger the scope-expansion checkpoint.

## Initialization protocol

At first entry into a new repository, run `skills/on-project-start/SKILL.md` before implementation.

Required outcomes:

1. Detect dominant stack signals (for example Spring Boot, AWS, Terraform, CDK, React).
2. Ask targeted boundary questions to the user before coding.
3. Record confirmed constraints into the project layer (`project/project-manifest.md`).

This converts boundary discovery from hardcoded assumptions into dynamic confirmation.

## Context isolation

Roles sharing a single conversation context will eventually drift, contaminate each other's state, and lose control on long tasks. Prevent this by isolating contexts.

### Task boundary rule

Each conceptual role (planner, architect, implementer, critic, reviewer) should run as a **separate agent invocation** with its own context. Do not switch roles within one long conversation.

- One task = one agent = one context.
- If a tool supports named subagents or new sessions, use them.
- If a tool only supports a single conversation, insert a **hard context break** between roles: summarize the previous role's output into a structured handoff artifact, then begin the next role with only that artifact as input.
- Changing **intent mode** within the same role is allowed when the current task scale permits a shared context. Changing **roles** still uses the stronger isolation rule.

**Scale-based relaxation**: For Small tasks, a single agent context is sufficient. For Medium tasks at `semi-auto` or `autonomous` trust level, planner and implementer may share a context if the tool does not easily support subagents. Strict isolation remains mandatory for Large tasks and for any task at `supervised` trust level.

### Handoff artifact

When one agent's work feeds into the next, pass a **structured handoff artifact** — not raw conversation history. Include: task, deliverable, key decisions (with DECISIONS.md refs), open risks, constraints for next step, and attached output. See `docs/agent-templates.md` → Handoff artifact template for the full format.

Minimum validity rules:

1. `Task`, `Deliverable`, `Key decisions`, `Constraints for next step`, and `Attached output` are required.
2. `Open risks` may be `N/A — none identified`, but may not be silently omitted.
3. Source and target intent modes should be included whenever the handoff crosses from planning to implementation, implementation to review, or implementation to documentation.
4. If a required field is missing, the handoff is invalid. The receiving role must request a corrected handoff or reconstruct the missing context before proceeding.

### Anti-patterns (banned)

- **Role ping-pong** — switching roles back and forth in the same context more than once. If you need a second opinion, spawn a new context.
- **Implicit handoff** — continuing from one role to the next without an explicit handoff artifact. The next agent must not rely on "what was said earlier."
- **Conversation-as-memory** — using scroll-back or prior messages as the source of truth. Use `DECISIONS.md`, handoff artifacts, and context anchors instead.

## Human checkpoint gates

Checkpoint behavior is governed by the trust level (see Trust level section above). The table below shows when each gate activates.

### Checkpoint gate outcomes

Each checkpoint gate produces one of three outcomes:

| Outcome | Behavior | When used |
|---------|----------|-----------|
| **STOP** | Halt execution. Present the checkpoint to the user and wait for approval before continuing. | Default for active gates at `supervised` level; destructive actions at all levels |
| **ADVISORY** | Log the checkpoint finding and continue without waiting. The finding is recorded in the trace and task summary but does not block progress. | Scope expansion at `autonomous` level; mid-implementation review at `semi-auto` for non-Large tasks |
| **PASS** | Gate does not activate. No output, no log entry. The step is silently skipped. | Gates that are inactive for the current trust level and scale combination |

When implementing a gate:

1. Check the activation matrix below to determine the outcome for the current trust level.
2. If the outcome is **STOP**, use the Checkpoint template from `docs/agent-templates.md`.
3. If the outcome is **ADVISORY**, use the Advisory template from `docs/agent-templates.md`: emit a single-line advisory in the task output and continue.
4. If the outcome is **PASS**, produce no output for this gate.

### Checkpoint activation matrix

| Gate | `supervised` | `semi-auto` | `autonomous` | Configurable autonomous override |
|---|---|---|---|---|
| Plan approval | STOP | STOP (Large/high-risk) / PASS | ADVISORY | `auto_proceed_on_plan: false` keeps STOP behavior |
| Destructive/irreversible actions | STOP | STOP | STOP by default | `halt_on_destructive_actions: false` |
| Scope expansion | STOP | STOP | ADVISORY / STOP (unrelated expansion) | `auto_proceed_on_scope_expansion` applies only within original intent |
| Stuck escalation (3 failures) | STOP | STOP | STOP by default | `halt_on_stuck_escalation: false` |
| Mid-implementation review (>5 files) | STOP | STOP (Large) / ADVISORY | PASS | none |
| Before final merge | STOP | ADVISORY | PASS | none |

### Always-safe operations (never need human approval)

These operations are safe by nature and agents may execute them automatically at any trust level:

- Reading files, searching code, listing directories
- Running tests and linters
- Running static analysis and type checkers
- Creating or switching git branches
- Writing to session memory or scratchpad
- Generating diffs and previewing changes (dry-run)

### Always-dangerous operations (require human approval by default)

These operations are irreversible or high-impact and require explicit human approval by default. In autonomous mode, they remain STOP behavior unless `autonomous_mode.halt_on_destructive_actions: false` is explicitly set:

- Deleting files or directories
- Dropping database tables or running destructive migrations
- `git push --force`, `git reset --hard`, amending published commits
- Modifying shared infrastructure, CI/CD pipelines, or deployment configs
- Publishing packages, creating releases, or pushing to `main`/`production` branches
- Modifying auth, permissions, or security configuration in production

### Checkpoint format

When stopping for approval, present: gate name, current state, proposal, risks, and decision needed. See `docs/agent-templates.md` → Checkpoint template for the full format. Never silently skip a checkpoint that is active for the current trust level.

## Autonomous execution mode

When `execution_mode: autonomous` is declared in `prompt-budget.yml` (or an equivalent project configuration file), agents substitute logged auto-proceed for the human wait states at most checkpoint gates.

**This mode is explicitly opt-in.** The default project mode is `semi-auto`. Never infer autonomous mode from context — it must be declared in configuration.

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
| 1. Plan approval | STOP — wait for "PROCEED" | ADVISORY — log plan to `DECISIONS.md`, then auto-proceed |
| 2. Destructive / irreversible actions | STOP — wait | STOP by default; may be relaxed via `halt_on_destructive_actions: false` |
| 3. Scope expansion | STOP — present expanded scope | ADVISORY / STOP — if expansion is within original intent: ADVISORY (log and proceed). If unrelated module added: STOP. |
| 4. Stuck escalation (3 fails) | STOP — report | STOP by default; may be relaxed via `halt_on_stuck_escalation: false` |
| 5. Mid-implementation review | STOP | PASS |
| 6. Before final merge | STOP | PASS |

### Non-bypassable rules in autonomous mode

Even with `execution_mode: autonomous`, the following remain hard stops:

- **Contradiction with `DECISIONS.md`** — never auto-resolve a contradiction. Stop and present the conflict with options. Proceeding autonomously on a known contradiction violates the decision log contract. This rule has no configuration override.

The rules below are enforced by default and **strongly recommended** to keep enabled. They can be relaxed in `prompt-budget.yml` under `autonomous_mode` only for fully isolated or sandboxed environments where the corresponding risk is explicitly accepted:

- **Destructive or irreversible actions** (gate 2) — deleting files, dropping tables, force-pushing, resetting branches, modifying shared infrastructure. Controlled by `halt_on_destructive_actions`. Keep `true` unless the environment is fully sandboxed.
- **Stuck escalation after 3 failed attempts** (gate 4) — agents must not loop forever. Stop and report. Controlled by `halt_on_stuck_escalation`. Keep `true` unless an external timeout mechanism is in place.
- **Severity-high findings from `risk-reviewer`** — any severity-high risk outcome is a hard stop by default. Do not auto-proceed on a severity-high finding; stop and present the finding for user review. Controlled by `halt_on_high_severity_risk`.

### Mandatory audit log in autonomous mode

> **Policy check**: Before writing, read `prompt-budget.yml` → `decision_log.policy`.
> If `policy: example_only`, **do not append to `DECISIONS.md`**. Record the auto-proceeded gate in the task completion summary or trace file instead. Skip the rest of this section.

Every gate that is auto-proceeded must be recorded. If `decision_log.policy` allows writes to `DECISIONS.md`, append using the standard format below; otherwise, follow the policy-check block above and record the event in the task completion summary or trace file instead.

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

When the routed workflow includes `risk-reviewer`, it still runs in autonomous mode, including post-implementation review when that workflow step is required. Its findings are recorded in the task completion summary. For any `risk-reviewer` run in autonomous mode, a severity-high finding is a default hard stop when `autonomous_mode.halt_on_high_severity_risk: true`. If that setting is `false`, the agent must log the severity-high finding and may continue autonomously. Severity-medium and lower findings are logged and accepted.

### Autonomous mode is not "skip planning"

Autonomous mode removes the **human wait states**, not the **work steps**. The agent still:

- Discovers the codebase before coding
- Classifies task scale with demand-triage
- Produces whatever level of plan the current task scale and workflow require
- Runs planner / critic / risk-reviewer steps when the routed workflow requires them
- Validates with the test-and-fix loop
- Records decisions in `DECISIONS.md`

The only difference is that the agent proceeds through these steps automatically instead of pausing for user "PROCEED" signals.

## Codebase discovery (repo-aware)

Before writing or modifying any code, perform these steps:

1. **Read related files** — identify and read the files that will be changed and their direct dependents. Do not guess file contents.
2. **Identify existing patterns** — look for naming conventions, folder structure, error handling style, logging patterns, and test conventions already in use.
3. **Follow repository conventions** — match the existing code style, framework idioms, and architectural patterns. Do not introduce a new pattern when an established one exists.
4. **Check dependency graph** — understand imports, module boundaries, and shared types before making cross-file changes.
5. **Read project-specific constraints** — check `project/project-manifest.md` and any `CONVENTIONS.md`, `ARCHITECTURE.md`, or similar files at the repo root.
6. **Apply workspace boundaries** — if `project/project-manifest.md` defines a `Workspace boundaries` section, determine the active boundary before loading domain rules. See *Workspace boundary masking* above.
7. **Use retrieval when configured** — if RAG-augmented or selective retrieval is set up (see `skills/memory-and-state/SKILL.md`), use it to identify relevant `DECISIONS.md` and `ARCHITECTURE.md` entries at task start. When a rule below requires a contradiction-critical read, retrieval may be used as the discovery step, but the final decision must still be checked against the relevant full entry text before proceeding.
8. **Validate documentation targets against reality** — for documentation or agent-framework work, verify that referenced files, directories, modules, commands, and scripts exist in the live repository before editing or reusing prior wording.

If you skip discovery, state what you skipped and why.

For documentation or agent-framework work, repository reality checks are part of scope, not optional polish. If a referenced artifact no longer exists or has moved, update the guidance to match the live repository instead of copying stale instructions forward.

## Validation loop (write → test → fix → repeat)

After every code change, follow this mandatory loop. **This loop runs autonomously** — the agent does not need human approval between iterations. It is an always-safe operation.

1. **Run tests** — execute the project's test suite (e.g., `go test ./...`, `npm test`, `pytest`, `mvn test`). Run the most targeted subset first, then broaden if needed.
2. **Run static analysis** — execute linters and type checkers (e.g., `go vet`, `eslint`, `mypy`, `cargo clippy`).
3. **Auto-fix on failure** — if tests or analysis fail, identify the root cause, apply the minimal fix, and re-run. Do not wait for human approval to retry.
4. **Repeat** — continue the loop until all tests pass and no new warnings are introduced.
5. **Escalate if stuck** — if the loop cannot converge after 3 attempts, stop and report the remaining failures to the user. In autonomous mode only, this stop may be relaxed via `autonomous_mode.halt_on_stuck_escalation: false`; if relaxed, log the unresolved failures prominently before continuing.

Never treat a change as complete until verification passes. If the project has no test suite, state that explicitly and describe what manual verification was done or is still needed.

### CI-driven risk review

When a CI pipeline triggers a risk review (rather than an interactive agent session), the following rules apply:

1. **Read-only mode** — the risk-reviewer does not modify code. It consumes trace files from `.agent-trace/` and produces review findings only.
2. **Input** — trace YAML files following the naming and format defined in `skills/observability/SKILL.md` → CI integration protocol.
3. **Output** — a review summary artifact (YAML or PR comment) listing findings with severity levels.
4. **Exit-code contract** — the CI step exits with code 0 (pass), 1 (severity-high finding), or 2 (parse error). See `skills/observability/SKILL.md` for the full contract.
5. **Blocking behavior** — severity-high findings fail the CI job. This is equivalent to the "severity-high finding from risk-reviewer" hard stop in interactive mode.
6. **No trust-level bypass** — CI-driven reviews always enforce severity-high blocking, regardless of trust level settings. Autonomous-mode overrides do not apply to CI pipelines.

### TDAI (Test-Driven AI) requirement

For new behavior (feature addition, contract extension, architecture-driven behavior change), agents must generate test cases before implementation.

Minimum policy:

1. Define expected behavior as test cases first.
2. Run tests to confirm failing baseline where applicable.
3. Implement minimal code to satisfy tests.
4. Re-run tests and static analysis.

Allowed exception:

- Trivial non-behavioral edits (copy changes, comment/doc-only edits, formatting-only fixes) may skip test-first ordering, but validation still remains mandatory when code is touched.

## Structured output and anti-drift

Long tasks cause agents to forget instructions, skip format requirements, and drift from the original objective. These rules prevent that.

### Mandatory structured preamble

Before producing any solution or implementation, agents must explicitly provide a brief, high-level summary of:

1. **Assumptions** — what is being assumed about the request, codebase, or constraints
2. **Constraints** — what limits apply (from `DECISIONS.md`, project-specific constraints, or the request itself)
3. **Proposed approach** — a short, high-level summary of the intended approach without detailed step-by-step reasoning

This must appear in the output before any code or implementation. Do not require or provide detailed internal reasoning.

### Mandatory first-response compliance block

The first response of any implementation task must include a visible compliance block so users can verify process adherence. The depth of this block depends on the trust level.

**At `supervised` trust level** — full compliance block with all fields:

1. **Read set** — list the files/rules read before implementation
2. **Scale** — `[SCALE: SMALL|MEDIUM|LARGE]` and evidence-based reason
3. **Workflow path** — Small simplification path or Medium/Large planning path, with justification
4. **Checkpoint map** — mandatory checkpoints that will be used in this task (or `N/A` with reason)

**At `semi-auto` trust level** — required for Medium and Large tasks only. Small tasks may skip the compliance block and proceed directly (but must still run triage internally).

**At `autonomous` trust level** — optional. The agent may omit the compliance block and proceed. Scale classification and DECISIONS.md checks still run internally but do not need to be reported unless issues are found.

If this block is missing at `supervised` trust level, the workflow is considered not started.

### Context anchor

At the start of every long task (more than one step or more than one file), produce a context summary with: objective, current step, completed items, remaining items, and active constraints. Update before each major step. See `docs/agent-templates.md` → Context anchor template for the format.

### Context compaction

Long tasks cause context growth that increases cost and reduces model accuracy. To prevent this:

- After completing each phase of a multi-phase task, produce a progress summary using `docs/agent-templates.md` → Compaction summary template and store it in session memory (see `skills/memory-and-state/SKILL.md` → Context compaction protocol).
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

Default to the shortest output that still lets the user verify assumptions, scope, validation, and blockers. Expand only when risk, ambiguity, or the user asks for more detail.

If a section is not applicable, write "N/A — [reason]" instead of omitting it.

### Mandatory deliverable structure

Non-review roles must produce final output using the Deliverable template in `docs/agent-templates.md`. The five required sections are: Proposal, Alternatives considered, Pros/Cons, Risks, Recommendation. Roles may add domain-specific sections but must not omit these five. Write `N/A — [reason]` for any section that genuinely does not apply.

Review-first roles use a different final-output contract:

- `risk-reviewer` and `critic` must lead with findings, ordered by severity.
- Then list open questions or assumptions.
- Then include residual risks or short summary.
- If there are no findings, state that explicitly.

Use the review output template in `docs/agent-templates.md` for these review-first roles. Findings-first review output takes precedence over the Deliverable template for review work.

### Small-task minimum output contract

Small tasks may simplify depth, but must keep explicit structure. The minimum output depends on the trust level:

**At `supervised` trust level** (full explicit output):

1. Compliance block
2. Structured preamble (inline allowed)
3. DECISIONS.md contradiction check result
4. Validation plan and targeted verification outcome
5. Mandatory deliverable structure (concise)

**At `semi-auto` or `autonomous` trust level** (streamlined):

1. DECISIONS.md contradiction check result (silent pass is acceptable — only report if contradiction found)
2. Implement the change directly
3. Run targeted validation and report outcome
4. Brief final summary of what changed and why (this may serve as the concise deliverable for Small tasks)

At all trust levels, Small tasks must not skip verification. The difference is output ceremony, not rigor. For Small tasks, the deliverable structure may be collapsed into a concise final summary as long as the user still receives the outcome, validation result, and any relevant follow-up note.

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

This escalation rule also applies to **context isolation violations** — if isolation violations appear 3+ times in the rolling window (as recorded by `isolation_status` in trace files), treat it as recurring friction and follow the same escalation procedure.

Do not rely on ad-hoc reminders once recurrence is detected.

### Self-evolution guardrails

When the self-evolution protocol (`docs/agent-playbook.md` → Self-evolution protocol) produces rule or skill improvement proposals:

1. **Human approval required** — evolution proposals always require explicit human approval before implementation, regardless of trust level. Autonomous-mode overrides do not apply to evolution proposals.
2. **Constitutional principles are immutable via evolution** — proposals that would weaken, remove, or reinterpret a constitutional principle must be rejected. Constitutional changes require a dedicated manual review process outside the evolution protocol.
3. **Core stability rules require risk review** — proposals targeting `core` stability rules must pass through `risk-reviewer` before being presented for human approval.
4. **Maximum 3 proposals per cycle** — to prevent churn, each evolution cycle produces at most 3 proposals. If more patterns are identified, prioritize by frequency and impact.
5. **Evidence requirement** — every proposal must cite at least one specific trace file, feedback entry, or quality signal metric. Proposals without concrete evidence are invalid.

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

Source of truth: `project/project-manifest.md`.

Keep project-local constraints, validation commands, and operational boundaries there. Do not duplicate active repo-specific constraints in this file unless you are documenting a temporary migration note.

## Decision log

Maintain a `DECISIONS.md` file (or equivalent) at the repository root to record:

- **What** was decided
- **Why** the decision was made (alternatives considered)
- **When** it was decided
- **Constraints** it introduces for future work

Agents should read this file during codebase discovery and append to it when making architectural or behavioral decisions that future work depends on.

### ADR automatic update

When a task changes system architecture (for example service boundary split/merge, integration pattern replacement, event topology change, deployment model change), agents must update architecture decision records in the same task.

Rules:

1. If `docs/adr/` exists, append or supersede an ADR in that directory.
2. If no ADR directory exists, append a full decision entry to `DECISIONS.md` and include architecture-change context.
3. Do not finalize implementation with architecture changes unless ADR/decision log is updated in the same change set.

### Decision archive lifecycle

When `DECISIONS.md` exceeds 50 entries or 30 KB, or when any memory health indicator reaches the "needs attention" threshold, archive inactive decisions to `DECISIONS_ARCHIVE.md`. See `skills/memory-and-state/SKILL.md` → Memory lifecycle management for the full procedure, safety checks, and health indicators.

Key rules:
- Archive only entries whose constraints are no longer enforced by current code
- Never archive based on date alone
- Each archived entry must include the reason it was archived
- Agents read `DECISIONS.md` by default; read archive only when working with legacy modules or when contradiction detection finds no match in active decisions

### Mandatory read-before-write

Before making any architectural or behavioral decision, agents **must**:

1. Read the relevant active decision entries needed to evaluate the proposed change. For small logs, this means reading `DECISIONS.md` in full. For large logs, retrieval/selective loading is allowed if it still loads the relevant full entries before making the decision.
2. If the task involves legacy code or historical migrations, search `DECISIONS_ARCHIVE.md` for related prior decisions if the archive file exists
3. Check whether the proposed change contradicts any relevant decision found in the active log or archive search results
4. If it contradicts: stop and present the contradiction to the user with both the existing decision and the proposed change. Do not silently override.

### Automatic decision capture

> **Policy check**: Before writing, read `prompt-budget.yml` → `decision_log.policy`.
> If `policy: example_only`, **do not append to `DECISIONS.md`**. Record the decision in the task completion summary, handoff artifact, or trace file instead. Skip the rest of this section.

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

This is a mandatory checkpoint — do not resolve contradictions autonomously. No trust level or bypass flag overrides this stop.

## Conflict resolution principle

When generic agent guidance conflicts with repository-specific practice, resolve in this order:

1. Explicit user instruction for the current task
2. Existing codebase practice and enforced repository constraints
3. Project Context (`project/project-manifest.md`, active decisions)
4. Domain Rules
5. Global Rules and model default preferences

Default rule:

- If playbook guidance conflicts with existing repository style, follow existing repository practice unless the user explicitly requests a refactor.
