# Adoption Guide

Use this guide when adapting the template into a new repository.

## Minimum installation

Copy these files first:

- `AGENTS.md`
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

Open `docs/operating-rules.md` and fill the `Project-specific constraints` section with your actual rules. Be concrete and specific — agents cannot follow "best practices", they can only follow explicit instructions.

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

Agents need to know exactly which commands to run. Add these to `docs/operating-rules.md` or a `CONTRIBUTING.md`:

```markdown
## Validation commands
- Unit tests: `go test ./...`
- Lint: `golangci-lint run`
- Type check: N/A (Go)
- Integration tests: `make test-integration`
- Build: `go build ./cmd/...`
```

### 3. Decision log (recommended)

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

### 4. Architecture overview (recommended)

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

### 5. Initialization protocol (recommended)

Add the `skills/on_project_start/SKILL.md` workflow to your first-session process so agents dynamically discover missing boundaries.

Expected first-session questions include:

- Framework-specific naming or package conventions
- Infra tooling choices (for example Terraform vs CDK)
- Deployment/runtime constraints that are not documented yet

## First customization pass

Edit these items immediately:

- repository module names
- safety rails
- validation commands and expectations
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

The full template loads all skills, roles, and format templates in every request. When adopted by a real project, trimming unused content reduces per-request token cost significantly.

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

### Step 3: Simplify format templates

After your team is comfortable with the workflow, consider condensing verbose format templates.

If you change or remove any template structure here, also update the corresponding requirements in `docs/operating-rules.md` (and any other repo rules documents) so the documented rules stay consistent with the templates your team is expected to use.

- **Deliverable structure** — if your team always produces the same 3 sections, reduce the 5-section template to match
- **Checkpoint format** — if your tool enforces approval natively, the checkpoint template can be shortened
- **Handoff artifact** — if you rarely chain agents, this can be removed entirely

### Step 4: Configure Layer 2 loading strategy

Use the prompt cache optimization skill (`skills/prompt-cache-optimization/SKILL.md`) to choose which skills load per task type. For small projects:

- **Minimal set**: `demand-triage` + `repo-exploration` only (all task types)
- **Standard set**: add `test-and-fix-loop` for implementation tasks
- **Full set**: use the canonical skill sets from the prompt cache skill (recommended for teams > 3)

### Step 5: Set a token budget with `prompt-budget.yml`

Create a `prompt-budget.yml` at the repo root to declare your project's prompt configuration:

```yaml
# prompt-budget.yml — Prompt budget configuration for this project
# Agents read this file to determine which skills and roles to load.

budget:
  layer1_target_tokens: 3000    # Target for static rules (operating-rules + agent-playbook)
  layer2_max_tokens: 6000       # Max for skills loaded per request
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
    - documentation-architect    # Not needed: docs are informal

skills:
  always_load:
    - demand-triage
    - repo-exploration
  on_demand:
    - test-and-fix-loop
    - error-recovery
    - memory-and-state
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

This file is informational — agents use it as guidance to select which skills and role templates to load. It does not enforce hard limits but makes the intended budget visible and auditable.

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
6. Review `Project-specific constraints` quarterly — remove stale rules, add new ones.
7. Run a **memory health check** whenever a health indicator triggers (>50 entries, >30 KB, >10 session files), or at least quarterly for low-volume projects:
   - If `DECISIONS.md` exceeds 50 entries or 30 KB, archive inactive decisions to `DECISIONS_ARCHIVE.md` (see `skills/memory-and-state/SKILL.md` → Memory lifecycle management)
   - Purge session memory files that were not promoted to repo memory
   - Verify no archived constraint is still referenced by current code
