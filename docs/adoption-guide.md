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

## Recommended maintenance loop

1. Update the source-of-truth docs first.
2. Sync tool-specific files second.
3. Review whether repeated prompts should graduate into templates or skills.
4. Remove stale roles rather than letting them drift.
5. Update `DECISIONS.md` when architectural decisions are made or reversed.
6. Review `Project-specific constraints` quarterly — remove stale rules, add new ones.
7. Run a **memory health check** quarterly:
   - If `DECISIONS.md` exceeds 50 entries, archive inactive decisions to `DECISIONS_ARCHIVE.md` (see `skills/memory-and-state/SKILL.md` → Memory lifecycle management)
   - Purge session memory files that were not promoted to repo memory
   - Verify no archived constraint is still referenced by current code
