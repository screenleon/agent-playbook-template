# Rules Quickstart

Prefer your tool's built-in behavior first. Only apply these rules for capabilities the tool does not already cover.

This is the minimal rule set for agents. Read this first, then expand into source docs only when needed.

## Loading rule

Read `prompt-budget.yml` → `budget.profile` to determine loading depth:

- **`nano`**: load only `docs/rules-nano.md`. Do NOT load this file or any other docs. No skills are loaded.
- **`minimal`**: this file is your complete Layer 1. Do NOT load `docs/operating-rules.md` or `docs/agent-playbook.md` unless you need details listed in "When to open full docs" below.
- **`standard`** (default): read this file first, then expand into `docs/operating-rules.md` and `docs/agent-playbook.md` for full rules.
- **`full`**: load complete `docs/operating-rules.md` + `docs/agent-playbook.md` immediately.

## Canonical docs

1. `docs/operating-rules.md` for safety, scope, validation, conflict handling
2. `docs/agent-playbook.md` for routing and role ownership
3. `DECISIONS.md` for active architectural constraints and project state

## Trust level

Default: `semi-auto`. Override per project or session.

- `supervised` — all checkpoints require human approval
- `semi-auto` — Small/low-risk tasks run autonomously; checkpoints for Large/destructive work
- `autonomous` — proceeds without approval except for default hard stops; gate behavior may be tuned via `prompt-budget.yml` → `autonomous_mode`

See `docs/operating-rules.md` → Trust level for the full activation matrix.

## Layered configuration

Use three layers:

1. Global: `rules/global/`
2. Domain: `rules/domain/`
3. Project: `project/project-manifest.md`

Precedence: Project > Domain > Global.

If same-layer conflicts remain:

1. narrower scope wins
2. latest dated rule wins
3. record tie-break in `DECISIONS.md`

## Mandatory workflow (compact)

1. Discover (`skills/repo-exploration/SKILL.md`). At `minimal` profile + single-file Small task: skip reading `ARCHITECTURE.md` unless it has substantive non-template content (>50 lines).
2. Initialize on first repo entry (at minimal profile: scan stack and conventions manually; at standard/full: use `skills/on-project-start/SKILL.md`)
3. Triage (`skills/demand-triage/SKILL.md`)
4. Check contradictions in `DECISIONS.md` (and archive for legacy)
5. For behavior changes: define tests before implementation (TDAI)
6. If a task is ambiguous, reduce ambiguity through planning or clarification before guessing across modules
7. Implement with minimal scope
8. Validate (test -> lint/typecheck -> fix -> repeat). Never mark complete until verification passes. If no test suite exists, state that explicitly.
9. Record decisions and ADR updates when architecture changes

## Hard constraints

- Never expose credentials or secrets.
- Never do destructive actions without approval unless the configured autonomous-mode gate override explicitly allows them.
- Do not silently ignore errors. Do not remove or skip failing tests to make the suite pass.
- Follow existing repository practice unless user explicitly asks for refactor.

## Always-dangerous operations (require approval)

- Deleting files or directories
- Dropping database tables or destructive migrations
- `git push --force`, `git reset --hard`, amending published commits
- Modifying CI/CD pipelines, deployment configs, or shared infrastructure
- Publishing packages, creating releases, or pushing to main/production
- Modifying auth, permissions, or security config in production

## Error recovery

1. Read the full error message — do not guess from partial output
2. Identify the root cause (specific file and line)
3. Fix only what is needed — do not refactor unrelated code
4. Re-run validation
5. Escalate after 3 failed attempts (see escalation points)

## Escalation points

- Contradiction with existing decision in `DECISIONS.md`
- Scope expansion beyond approved plan (or beyond original intent in autonomous mode)
- Same error persists after 3 fix attempts
- Architecture change without ADR/decision update

## When to open full docs

- Need trust-level gate details -> `docs/operating-rules.md`
- Need role routing details -> `docs/agent-playbook.md`
- Need layered governance details -> `docs/layered-configuration.md`

## Constitutional principles (non-bypassable)

These apply at ALL profiles. No trust level, flag, or override can weaken them.

1. Never expose credentials in any artifact
2. Never execute unvalidated input as code
3. Never modify production data without backup verification
4. Never disable authentication or authorization
5. Never suppress security test failures

Violation = hard stop regardless of execution mode. See `docs/operating-rules.md` → Constitutional principles for full text.

## Checkpoint outcomes

- **STOP** — halt and wait for approval
- **ADVISORY** — log finding, continue
- **PASS** — no output, skip silently

At `semi-auto` (default): destructive actions → STOP; Small tasks → most gates PASS.
Full matrix: `docs/operating-rules.md` → Checkpoint activation matrix.

## Minimal-profile roles

When `budget.profile: minimal`, only these roles are active:

- **application-implementer** — general product and frontend implementation
- **critic** — adversarial review of plans and proposals before approval

All other roles are disabled. Do not attempt to route to them.
Minimal profile is designed for Small tasks only. If demand-triage classifies a task as Medium or Large, escalate to the user and recommend switching to standard or full profile.
For `standard` and `full` profiles, see `docs/agent-playbook.md` → Role definitions.

## Output style at minimal profile

Produce the briefest acceptable output:

- No compliance block for Small tasks at `semi-auto` (optional per demand-triage)
- No context anchor (single-step tasks do not need drift prevention)
- Implementation summary: ≤ 3 sentences
- Error messages: include file + line; do not reproduce surrounding code blocks
