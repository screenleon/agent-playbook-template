# Adoption Guide

Use this guide when adapting the template into a new repository.

## Minimum installation

Copy these files first:

- `AGENTS.md`
- `prompt-budget.yml`
- `docs/rules-nano.md`
- `docs/rules-quickstart.md`
- `docs/operating-rules.md`
- `docs/agent-playbook.md`

Then choose any of the following that match your toolchain:

- `.claude/agents/` for Claude-compatible project subagents
- `.github/copilot-instructions.md` for GitHub Copilot repository instructions
- `docs/agent-templates.md` for generic reusable prompts
- `skills/` for reusable workflow packaging

## Critical first customization (do not skip)

The template will produce vague, unusable agent behavior until you fill in these items:

### 0. Layered configuration scaffolding (mandatory)

Create and maintain these paths:

- `rules/global/` for cross-project core rules
- `rules/domain/` for domain-specific rules
- `project/project-manifest.md` for project-local boundaries

Precedence is: Project Context -> Domain Rules -> Global Rules.

For placement criteria, conflict resolution details, and anti-patterns, follow `docs/layered-configuration.md`.

### 1. Project-specific constraints (mandatory)

Open `project/project-manifest.md` and fill the `Non-negotiable constraints` section with your actual rules. Be concrete and specific — agents cannot follow "best practices", they can only follow explicit instructions.

Good examples:

```markdown
- Use raw SQL with sqlc; no ORM
- Do not modify the DB schema without a migration file in db/migrations/
- Pricing logic must use JSONB rule definitions in the pricing_rules table
- All HTTP handlers must use the shared middleware stack in internal/middleware/
- Authentication uses JWT with RS256; do not switch algorithms
- Frontend state management uses Zustand; do not introduce Redux
- All API responses follow the envelope format in docs/api-envelope.md
- Error codes must be registered in internal/errors/codes.go
```

Bad examples (too vague for agents):

```markdown
- Follow best practices
- Write clean code
- Use appropriate patterns
```

### 2. Validation commands (mandatory)

Agents need to know exactly which commands to run. Add these to `project/project-manifest.md` under `Build and validation commands` (or mirror them in `CONTRIBUTING.md` if you keep contributor-facing setup there):

```markdown
## Validation commands
- Unit tests: `go test ./...`
- Lint: `golangci-lint run`
- Type check: N/A (Go)
- Integration tests: `make test-integration`
- Build: `go build ./cmd/...`
```

### 3. Decision log (effectively mandatory)

Create a `DECISIONS.md` at the repo root:

```markdown
# Decisions

## 2024-01-15: Use sqlc instead of GORM
- Why: Type safety, predictable queries, no magic
- Constraint: All queries must be in .sql files under db/queries/

## 2024-02-01: JSONB for pricing rules
- Why: Business needs frequent rule changes without migrations
- Constraint: Pricing logic reads from pricing_rules table, never hardcoded
```

### 4. Architecture overview (strongly recommended; required for unfamiliar-module work)

Create an `ARCHITECTURE.md` or fill it into your README to help agents understand the codebase structure:

```markdown
## Module map
- cmd/api/         → HTTP server entrypoint
- internal/handler/ → HTTP handlers
- internal/service/ → Business logic
- internal/repo/    → Database access (sqlc)
- db/migrations/    → SQL migrations
- db/queries/       → sqlc query files
```

### 5. Initialization protocol (required on first repo entry)

Add the `skills/on-project-start/SKILL.md` workflow to your first-session process so agents dynamically discover missing boundaries.

Expected first-session questions include:

- Framework-specific naming or package conventions
- Infra tooling choices (for example Terraform vs CDK)
- Deployment/runtime constraints that are not documented yet

### 6. Enabling CI agentic review (optional)

If your repository uses `.agent-trace/` trace files (see `skills/observability/SKILL.md`), you can enable automated risk review in CI:

1. **Copy the workflow** — `.github/workflows/agent-review.yml` provides a skeleton GitHub Actions job.
2. **Configure trigger** — by default, the workflow runs on `pull_request` when `.agent-trace/` files change. Adjust paths or add `workflow_dispatch` as needed.
3. **Keep or tune the review script** — the template now includes a starter `scripts/agent-review.sh`. Keep the default rubric or tighten it for your repo.
4. **Set severity threshold** — by default, any severity-high finding fails the job. To also fail on medium findings, modify the script's exit logic.

See `docs/operating-rules.md` → CI-driven risk review for the operational rules that apply during CI reviews.

### 7. Run an adoption audit (recommended)

After the first customization pass, run:

```bash
bash scripts/adoption-audit.sh --strict
```

This catches the most common adoption misses:

- blank `project/project-manifest.md` fields
- untouched project-local constraints in `project/project-manifest.md`
- empty `DECISIONS.md`
- unchanged template `ARCHITECTURE.md`
- missing `scripts/agent-review.sh` when CI review is enabled

## First customization pass

Edit these items immediately:

- repository module names
- safety rails
- build and validation commands in `project/project-manifest.md`
- project-specific constraints (see above)
- role names you do or do not want to keep
- review and merge expectations

## Optional simplification

If your team is small or your project is simple, you can remove roles you do not need.

Good candidates to remove early:

- `backend-architect` in a frontend-only repo
- `ui-image-implementer` in a backend-only repo
- `documentation-architect` if documentation is not a repeated workflow yet

## Prompt budget trimming

The full template can load a broad set of skills, roles, and format templates depending on `budget.profile` and task triggers. When adopted by a real project, trimming unused content reduces per-request token cost significantly.

### Step 1: Remove unused role templates

Delete agent definitions and templates for roles your project does not use. Common removals:

| If your project is… | Safe to remove |
|----------------------|----------------|
| Frontend-only | `backend-architect` agent + template |
| Backend-only | `ui-image-implementer` agent + template, `skills/design-to-code/` |
| Small team (1–2 devs) | `critic`, `risk-reviewer` (inline reviews instead) |
| No documentation workflow | `documentation-architect` agent + template, `skills/documentation-architecture/` |

Update `docs/agent-playbook.md` routing table and `.github/copilot-instructions.md` after removing roles.

### Step 2: Remove unused skills

Each skill adds ~1,500–3,500 tokens when loaded. Delete skill folders that do not match your workflow:

- `skills/design-to-code/` — only needed for screenshot-driven UI work
- `skills/documentation-architecture/` — only needed for docs-as-deliverable workflows
- `skills/feature-planning/` — can be removed if all work is Small/Medium scale
- `skills/backend-change-planning/` — can be removed in frontend-only projects
- `skills/mcp-validation/` — can be removed if the project does not use MCP tools

### Step 3: Simplify format templates

After your team is comfortable with the workflow, consider condensing verbose format templates.

If you change or remove any template structure here, also update the corresponding requirements in `docs/operating-rules.md` (and any other repo rules documents) so the documented rules stay consistent with the templates your team is expected to use.

- **Deliverable structure** — if your team always produces the same 3 sections, reduce the 5-section template to match
- **Checkpoint format** — if your tool enforces approval natively, the checkpoint template can be shortened
- **Handoff artifact** — if you rarely chain agents, this can be removed entirely

### Step 4: Choose a budget profile

Set `budget.profile` in `prompt-budget.yml` based on your token constraints:

| Your situation | Recommended profile | Estimated Layer 2 cost |
|----------------|---------------------|------------------------|
| Extremely tight token limit, single-file edits only | `nano` | ~0 Layer 2 tokens |
| Tight token limit (< 16K context), solo dev, pay-per-token | `minimal` | ~3,000–4,000 tokens |
| Typical team, moderate budget (16K–32K context) | `standard` (default) | ~7,000–10,000 tokens |
| Large team, generous budget (32K+ context), high-risk project | `full` | ~12,000–18,000 tokens |

For `minimal` profile:
- Only `demand-triage` and `repo-exploration` are loaded as skills
- The agent uses its native capabilities for testing, error handling, and memory
- Small tasks only; if triage returns Medium or Large, switch to `standard` or `full`

For `standard` profile:
- All 5 Always-tier skills load; Conditional skills activate by trigger
- Good balance of safety and token cost for most projects

For `full` profile:
- All applicable skills and roles are available
- Recommended when compliance, risk, or project complexity justifies the token cost

See `docs/agent-playbook.md` → Budget profiles for the full specification and `docs/prompt-budget-examples.md` for example configurations per profile.

### Step 5: Set a token budget with `prompt-budget.yml`

Create a `prompt-budget.yml` at the repo root to declare your project's prompt configuration:

```yaml
# prompt-budget.yml — Prompt budget configuration for this project
# Agents read this file to determine which skills and roles to load.

execution_mode: semi-auto

budget:
  profile: standard
  layer1_target_tokens: 4000    # Target after profile-aware Layer 1 loading
  layer2_max_tokens: 8000       # Max for skills loaded per request
  layer3_max_tokens: 3000       # Max for DECISIONS.md + ARCHITECTURE.md

roles:
  enabled:
    - feature-planner
    - application-implementer
    - risk-reviewer
    - critic
  disabled:
    - backend-architect          # Not needed: frontend-only project
    - ui-image-implementer       # Not needed: no design-to-code workflow
    - integration-engineer       # handled inline by application-implementer
    - documentation-architect    # Not needed: docs are informal

skills:
  always_load:
    - demand-triage
    - repo-exploration
    - test-and-fix-loop
    - error-recovery
    - memory-and-state
  on_demand:
    - prompt-cache-optimization
  disabled:
    - design-to-code             # Not needed
    - documentation-architecture # Not needed
    - feature-planning           # All tasks are Small/Medium
    - backend-change-planning    # Frontend-only

trimming:
  decisions_archive_threshold_kb: 30
  decisions_archive_threshold_entries: 50
  session_memory_max_files: 10
```

This file is informational — agents use it as guidance to select which skills and role templates to load. It does not enforce hard limits but makes the intended execution mode, budget profile, and workflow surface visible and auditable.

### Trimming impact estimate

| Action | Estimated savings per request |
|--------|-------------------------------|
| Remove 1 unused role template | ~200–400 tokens |
| Remove 1 unused skill | ~1,500–3,500 tokens |
| Condense format templates | ~300–500 tokens |
| Configure Layer 2 minimal set | ~3,000–6,000 tokens vs full set |
| Total (aggressive trim) | ~5,000–10,000 tokens |

For a project running 50 agent requests/day, aggressive trimming can save 250K–500K tokens/day.

## Recommended maintenance loop

1. Update the source-of-truth docs first.
2. Sync tool-specific files second.
3. Review whether repeated prompts should graduate into templates or skills.
4. Remove stale roles rather than letting them drift.
5. Update `DECISIONS.md` when architectural decisions are made or reversed.
6. Review `project/project-manifest.md` quarterly — remove stale rules, add new constraints, and keep validation commands current.
7. Run a **memory health check** whenever a health indicator triggers (>50 entries, >30 KB, >10 session files), or at least quarterly for low-volume projects:
   - If `DECISIONS.md` exceeds 50 entries or 30 KB, archive inactive decisions to `DECISIONS_ARCHIVE.md` (see `skills/memory-and-state/SKILL.md` → Memory lifecycle management)
   - Purge session memory files that were not promoted to repo memory
   - Verify no archived constraint is still referenced by current code

## Autonomous execution mode

By default, agents pause at checkpoint gates and wait for human approval ("PROCEED"). For teams that want agents to operate without human confirmation — for example in CI/CD pipelines or prototyping environments — the template supports an autonomous mode that replaces human wait states with automatic logging and proceeding.

### What autonomous mode changes

Autonomous mode removes the **human wait states**, not the **work steps**. The agent still discovers the codebase, classifies scale, plans, critiques, implements, validates, and records decisions. The only change is that the agent proceeds automatically instead of pausing for your "PROCEED" signal.

| Step | Supervised mode | Autonomous mode |
|------|----------------|-----------------|
| Plan approval | Agent stops and waits | Agent logs plan to `DECISIONS.md`, proceeds |
| Scope expansion | Agent stops and presents | Agent logs expansion, proceeds if within original intent |
| Mid-implementation review | Agent pauses (recommended) | Agent skips |
| Before-merge review | Agent pauses (recommended) | Agent skips |

### What autonomous mode does NOT change

These remain default/recommended stop conditions in autonomous mode unless you explicitly relax the corresponding `prompt-budget.yml` flags:

- **Destructive or irreversible actions** — file deletion, table drops, force-push, branch reset. By default these require your approval when `halt_on_destructive_actions: true`. Only set `false` in fully isolated sandbox environments.
- **Stuck escalation** — if an error persists after 3 fix attempts, the agent stops and reports when `halt_on_stuck_escalation: true`. Do not disable this unless you have an external timeout mechanism in place.
- **DECISIONS.md contradictions** — if a proposed change conflicts with an existing decision, the agent stops and presents both sides. Auto-resolution is never allowed. This rule has no configuration override.
- **Severity-high risk findings** — if the risk-reviewer finds a severity-high issue during plan assessment, the agent stops when `halt_on_high_severity_risk: true`. Only set `false` if the codebase is sandboxed and risk findings are pre-acknowledged.

### How to enable autonomous mode

**Step 1**: In `prompt-budget.yml`, change `execution_mode` from `supervised` to `autonomous`:

```yaml
execution_mode: autonomous

autonomous_mode:
  auto_proceed_on_plan: true
  auto_proceed_on_scope_expansion: true
  halt_on_destructive_actions: true      # Keep true unless fully sandboxed
  halt_on_stuck_escalation: true         # Always keep true
  skip_critic_role: false                # Keep false for better quality
  halt_on_high_severity_risk: true       # Keep true for safety
```

**Step 2**: Ensure `DECISIONS.md` is in a good state before enabling autonomous mode. The agent will auto-log decisions here — a messy decision log will produce noisy entries.

**Step 3**: If your project uses destructive operations as a normal part of its workflow (e.g., a data-migration script that drops temporary tables), document that context in `project/project-manifest.md` so the agent and user understand why the operation exists. This documentation does **not** bypass the destructive-action gate; actual auto-execution still depends on `autonomous_mode.halt_on_destructive_actions`.

**Step 4**: Review `DECISIONS.md` after the first few autonomous runs to verify the auto-logged entries are sensible.

### Risk tradeoffs

| Risk | Mitigation |
|------|-----------|
| Agent makes a wrong architectural decision without human review | Plan is logged to `DECISIONS.md`; review logs post-hoc and add a correcting entry if needed |
| Scope creeps silently | Gate 3 (scope expansion within original intent) is still logged; unrelated module additions always stop |
| Destructive action executed automatically | Gate 2 is non-bypassable by default (`halt_on_destructive_actions: true`) |
| Critic findings ignored | Critique is embedded in the handoff artifact; implementers must address each point |
| Agent loops on errors | Gate 4 is non-bypassable by default (`halt_on_stuck_escalation: true`) |

### When not to use autonomous mode

- Schema migrations on production data
- Permission or security model changes
- Payment, billing, or financial logic
- Any task that will be run unreviewed in a production environment
- First run on a new codebase (discover patterns in supervised mode first)

## Tool adapter reference

The role model in this template is conceptual. Use the table below to find the right integration surface for each tool.

| Tool | System-level instructions | Per-task instructions | Subagent / role support |
|------|--------------------------|----------------------|------------------------|
| **Claude Code** | `.claude/agents/*.md` auto-loaded per role | `skills/*/SKILL.md` referenced on demand | Named subagents via `.claude/agents/` |
| **GitHub Copilot** | `.github/copilot-instructions.md` auto-injected | `.github/prompts/*.prompt.md` invoked via `#` | No native subagents; use prompt files as role templates |
| **Cursor** | `.cursor/rules/*.mdc` or `.cursorrules` | Inline `@`-mentioned files | No native subagents; use rules files as role templates |
| **Windsurf** | `.windsurfrules` | Referenced files | No native subagents; use rules file per role |
| **Custom OpenAI API** | `system` message (Layer 1+2) | `user` message prefix (Layer 3+4) | No native subagents; spawn separate API calls per role |
| **Codex CLI** | `AGENTS.md` + `docs/operating-rules.md` via repo context | Role templates from `docs/agent-templates.md` | No native subagents; use prompt templates |

## Intent mode mapping

`intent mode` is the current phase of work: `analyze`, `implement`, `review`, or `document`.

Adoption rule:

1. Map **role** to the tool's strongest long-lived instruction surface.
2. Map **intent mode** to the tool's lightest per-task surface.
3. Do not create a separate agent for every mode unless the tool already makes that cheap and clear.
4. Same-role mode changes may stay in one session. Role changes should still use a new session, subagent, or explicit handoff artifact when the workflow requires isolation.

### Recommended mapping by tool family

| Tool family | Map role to | Map intent mode to | Same-role mode switch |
|-------------|-------------|--------------------|-----------------------|
| Native subagent tools | subagent definition | task preamble, handoff field, or session label | keep same subagent unless risk/scale requires a new context |
| Repo-rules tools without subagents | role-specific rule/prompt file | first 1-3 lines of the task prompt | stay in one conversation and restate current mode |
| Raw API orchestration | system prompt variant or selected role template | task metadata field or user-message prefix | same API thread/call chain is fine for bounded tasks |

### Canonical prompt tags

When a tool does not provide a structured field for intent mode, use an explicit tag near the top of the task input:

```text
Role: application-implementer
Intent mode: analyze
Task: Inspect the current API response shape and propose the minimal change.
```

When the same role moves into implementation, restate the mode and scope before edits begin:

```text
Role: application-implementer
Intent mode: implement
Approved scope: update src/api/users.ts and its targeted tests only.
```

### Tool-specific intent-mode guidance

#### Claude Code-style tools

- Map `role` to `.claude/agents/*.md` or the tool's native subagent selection.
- Carry `intent mode` in the task preamble or handoff artifact, not in a separate permanent agent definition.
- Keep the same subagent when moving from `analyze` to `implement` for Small tasks and relaxed Medium tasks.
- Switch subagents when the role changes, not merely because the mode changed.

#### GitHub Copilot-style tools

- Keep role behavior in `.github/copilot-instructions.md` and prompt files.
- Put `intent mode` in the top lines of the prompt file or user request.
- Because there are no native subagents, treat mode as a declared task state, not as a separate prompt family unless your team wants stricter separation.

#### Cursor / Windsurf-style tools

- Keep role behavior in rule files.
- Put `intent mode` in the inline task preamble.
- For same-role analyze-to-implement flows, keep one chat and restate the mode switch explicitly before edits.
- For role changes, start a fresh chat or supply a handoff block so the new role does not inherit the entire old conversation implicitly.

#### Custom OpenAI API / orchestration layers

- Select the role template in the `system` message or orchestration layer.
- Send `intent_mode` as explicit request metadata when possible; otherwise include it at the top of the `user` message.
- For same-role mode switches, keep the same role template and send a new message that restates the mode and approved scope.
- For role changes, start a new call chain with a structured handoff artifact instead of replaying full raw history.

### Cursor setup

1. Create `.cursor/rules/` directory (or use `.cursorrules` at the repo root for older versions).
2. Create one `.mdc` file per always-loaded instruction, e.g.:
   - `.cursor/rules/operating-rules.mdc` — paste or reference `docs/operating-rules.md`
   - `.cursor/rules/agent-playbook.mdc` — paste or reference `docs/agent-playbook.md`
3. For role-specific behavior, create a rule file per role and use it in the relevant context.
4. Put `Intent mode: ...` in the first lines of the request; update that line when the same role changes phase.
5. Reference skills by asking the agent to read the relevant `skills/*/SKILL.md` file at the start of a task.

### Windsurf setup

1. Create `.windsurfrules` at the repo root.
2. Include the core instructions from `AGENTS.md`, `docs/operating-rules.md`, and `docs/agent-playbook.md`.
3. For token efficiency, summarize only the most critical rules and link to full files for on-demand reading.
4. Put `Intent mode: ...` near the top of each task request so phase changes stay explicit even in one chat.
5. Skills and role templates work as referenced files — ask the agent to read them as needed.

### Custom OpenAI API setup

1. Apply the same profile-aware loading rules as the repository docs: `nano` loads only `docs/rules-nano.md`; `minimal` uses `docs/rules-quickstart.md` as complete Layer 1; `standard`/`full` may place full Layer 1 docs in the `system` message.
2. Place Layer 2 (selected skills) at the start of the `user` message, before the task description.
3. Place Layer 3 (`DECISIONS.md`, `ARCHITECTURE.md`) after Layer 2 in the `user` message.
4. Place the actual task query and current file content last (Layer 4).
5. For same-role mode switches, keep the same role template and send `Intent mode: ...` plus the narrowed scope in the next user message.
6. For multi-role workflows, spawn separate API calls for each role using the same Layer 1 prefix to maximize cache hits.

See `skills/prompt-cache-optimization/SKILL.md` → Tool-specific adaptation for more detail on cache-aware loading per tool.
