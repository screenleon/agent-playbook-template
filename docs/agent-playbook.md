# Agent Playbook

## Three-layer architecture

All agent work follows three layers:

1. **Rules** (`docs/operating-rules.md`) — hard constraints: safety, scope, codebase discovery, validation loop, error recovery, project-specific constraints, decision log.
2. **Skills** (`skills/*/SKILL.md`) — reusable capabilities: repo exploration, test-and-fix loop, error recovery, memory management, plus domain skills (planning, backend, frontend, design, docs).
3. **Loop** — every implementation follows: Plan → **Approve** → Read → Implement → Test → Fix → Repeat → Record.

## Repository asset map

- Global entrypoint: `AGENTS.md`
- Project subagents: `.claude/agents/*.md`
- Reusable templates: `docs/agent-templates.md`
- Reusable skills: `skills/*/SKILL.md`
- Repo-wide Copilot instructions: `.github/copilot-instructions.md`
- Decision log: `DECISIONS.md` (created per repo)
- Architecture overview: `ARCHITECTURE.md` (created per repo)

## Source of truth and precedence

Use this precedence order when documents overlap:

1. `docs/operating-rules.md` for safety, scope control, validation, and destructive-action rules
2. `docs/agent-playbook.md` for routing, role definitions, and workflow ownership
3. `AGENTS.md` as the short root entrypoint into those two files
4. `docs/agent-templates.md` as reusable prompt scaffolds
5. `.claude/agents/`, `skills/`, and `.github/copilot-instructions.md` as tool-specific implementations of the same role model

If a tool-specific file drifts from the source-of-truth docs (`docs/operating-rules.md` and this playbook), update the tool-specific file to match them.

## Tool portability

The role names in this template are conceptual. Different tools expose them differently:

- Claude-style tooling can map them into `.claude/agents/*`
- Copilot-style tooling can reference them through repository instructions and prompt files
- Codex-style or generic chat tooling can use the same role names through prompt templates and local repo docs

Do not assume every tool supports named subagents. Keep the role model stable even when the implementation surface changes.

## Default routing

### Use the planning agent first when

- a request impacts more than one module
- a request changes API contracts, schemas, migrations, events, or background jobs
- a request touches auth, permissions, audit, uploads, security, or notifications
- a request is still ambiguous and needs scope, order, or risk clarification
- a request is driven by screenshots or mockups and also changes flow or state

### Use specialist agents directly when

- backend contract and domain work is isolated
- general application or frontend implementation is isolated and does not need a planning-first phase
- image-led UI implementation is isolated
- integration work is mostly wiring existing pieces together
- documentation is the primary deliverable
- final review is focused on bugs, security, and regressions

## Role definitions

### `feature-planner`

- defines scope, non-goals, impacted modules, dependencies, order, and validation
- owns ambiguity reduction before implementation starts

### `backend-architect`

- owns contract-first backend design, schema changes, permissions, audit, and high-risk backend behavior

### `application-implementer`

- owns general product implementation that is neither pure backend architecture nor mostly integration wiring
- covers ordinary frontend, service-layer, or app behavior work where a dedicated image-led flow is unnecessary

### `ui-image-implementer`

- owns design-to-code tasks driven by screenshots, mockups, or visual specs

### `integration-engineer`

- owns wiring across API, state, navigation, side effects, caching, and complete user journeys

### `documentation-architect`

- owns repository instructions, onboarding docs, ADRs, runbooks, process docs, and architecture explanations
- optimizes for long-term maintainability and future agent readability

### `risk-reviewer`

- owns bug finding, regression detection, permission review, security review, and testing gaps

## Suggested workflow

### Mandatory steps for all workflows

Every workflow below implicitly includes these steps:

1. **Discover** — run the `repo-exploration` skill before coding
2. **Structured preamble** — state assumptions, constraints, and proposed approach before producing output (see `docs/operating-rules.md` structured output rules)
3. **Validate** — run the `test-and-fix-loop` skill after every code change
4. **Recover** — use the `error-recovery` skill when anything fails
5. **Record** — use the `memory-and-state` skill to log decisions and update architecture docs

### Mandatory checkpoint gates

These gates require the agent to **STOP and wait for user approval**:

- **After planning, before implementation** — the planning agent presents its plan; implementation agents do not start until the user approves.
- **On scope expansion** — if implementation reveals the need to change more modules or contracts than planned, stop and request approval for the expanded scope.
- **On contradiction** — if the proposed work contradicts `DECISIONS.md`, stop and present the conflict.
- **On stuck** — after 3 failed fix attempts, stop and escalate.

See `docs/operating-rules.md` → Human checkpoint gates for the full list and format.

### New feature

`feature-planner` -> **user approval** -> `backend-architect`, `application-implementer`, and/or `ui-image-implementer` -> `integration-engineer` -> `documentation-architect` as needed -> `risk-reviewer`

### High-risk backend change

`feature-planner` -> **user approval** -> `backend-architect` -> `risk-reviewer`

### General application change

If it is bounded and low ambiguity:

`application-implementer` -> `risk-reviewer`

If it also changes flow, state, or contracts:

`feature-planner` -> **user approval** -> `application-implementer` -> `integration-engineer` -> `risk-reviewer`

### Image-led UI change

If it is visual only:

`ui-image-implementer` -> `risk-reviewer`

If it also changes logic or flow:

`feature-planner` -> **user approval** -> `ui-image-implementer` -> `integration-engineer` -> `risk-reviewer`

### Documentation-heavy change

`feature-planner` as needed -> **user approval** -> `documentation-architect` -> `risk-reviewer` when technical correctness matters

## Ownership principles

- Planning agents define scope, order, dependencies, and validation.
- Implementation agents stay inside their domain and avoid unnecessary expansion.
- Integration agents close loops across state, navigation, side effects, and data flow.
- Documentation agents keep instructions, architecture notes, and operational docs aligned with the actual workflow.
- Review agents lead with findings, not summaries.

## Maintenance principles

- Keep root guidance short and stable.
- Put details in focused docs, agents, and skills.
- Promote repeated prompts into reusable templates.
- Keep templates generic unless a repository-specific constraint truly matters.
- Prefer one conceptual role model with many tool-specific implementations, not many unrelated role models.
