# Anti-Patterns Reference

This document collects common mistakes teams make when adopting the agent playbook
template. Each anti-pattern includes the symptom, the root cause, and the correct
approach.

Use this as a pre-flight checklist before your first production task.

---

## Configuration anti-patterns

### AP-C1: Provider model IDs in tracked canonical docs

**Symptom**: `prompt-budget.yml` contains entries like:

```yaml
model_routing:
  provider_model_map:
    default: claude-3-5-sonnet-20241022
```

**Problem**: Commits a vendor-specific model string into the repository source of
truth. Future model deprecations force a team-wide doc update instead of a local config
change, and it leaks provider preference into the framework contract.

**Correct approach**: Keep canonical docs vendor-neutral. Put concrete model IDs in
`prompt-budget.local.yml` (git-ignored) or adapter runtime config:

```yaml
# prompt-budget.local.yml (not tracked)
model_routing:
  enabled: true
  provider_model_map:
    balanced: claude-3-5-sonnet-20241022
    deep: claude-opus-4
```

---

### AP-C2: `halt_on_destructive_actions: false` outside a sandbox

**Symptom**: `prompt-budget.yml` sets `autonomous_mode.halt_on_destructive_actions: false`
in a real production repository.

**Problem**: Allows the agent to execute `rm -rf`, `git reset --hard`, `git push --force`,
or database drops without human confirmation. In a real repo, this can cause permanent
data loss.

**Correct approach**: Only disable this in fully isolated sandbox or CI environments where
state is ephemeral and can be reset. Leave it `true` for any repo with real data or a
shared `main` branch.

---

### AP-C3: Disabling a role but not removing its agent file

**Symptom**: A role appears in `roles.disabled` in `prompt-budget.yml`, but the
corresponding `<name>.md` file still exists in `.claude/agents/` (or equivalent).

**Problem**: The agent runtime may still load and route to the agent file, contradicting
the playbook's disabled list. Governance intent is not enforced.

**Correct approach**: When disabling a role, also remove or rename its agent definition file:

```bash
# For Claude Code
rm .claude/agents/backend-architect.md

# For OpenCode
rm .opencode/agents/backend-architect.md
```

---

### AP-C4: `execution_mode: autonomous` without configuring `autonomous_mode`

**Symptom**: `prompt-budget.yml` declares `execution_mode: autonomous` but has no
`autonomous_mode` block, leaving all defaults unreviewed.

**Problem**: The default autonomous gates (`halt_on_destructive_actions: true`,
`halt_on_stuck_escalation: true`) are safe, but teams often discover they need
`auto_proceed_on_plan: false` for high-risk repos only after a mistake.

**Correct approach**: Always declare the `autonomous_mode` block explicitly when
using `autonomous` mode so every gate is a conscious decision:

```yaml
execution_mode: autonomous
autonomous_mode:
  auto_proceed_on_plan: true          # OK for low-risk repos
  auto_proceed_on_scope_expansion: false  # stop for scope changes
  halt_on_destructive_actions: true   # always recommend true
  halt_on_stuck_escalation: true      # always recommend true
  skip_critic_role: false
  halt_on_high_severity_risk: true
```

---

## Project manifest anti-patterns

### AP-M1: Vague constraints in project-manifest.md

**Symptom**: `project/project-manifest.md` contains entries like:

```markdown
- Follow best practices
- Write clean code
- Use appropriate patterns
```

**Problem**: Agents cannot follow abstract guidance. "Best practices" is not a
constraint — it is an adjective. The agent will make up what it thinks "best" means
and often make wrong assumptions.

**Correct approach**: Be concrete and verifiable. A good constraint names a specific
technology, file, command, or behavior:

```markdown
- Use raw SQL with sqlc; no ORM
- Do not modify db/schema/ without a migration file in db/migrations/
- All API handlers must log a request-id from the incoming X-Request-ID header
- Frontend state management uses Zustand only; do not introduce Redux
```

---

### AP-M2: Empty DECISIONS.md

**Symptom**: `DECISIONS.md` exists but contains only the template example or is empty.

**Problem**: Agents run contradiction checks against `DECISIONS.md` before planning.
An empty file means every agent task starts from zero — no prior context, no
constraint history. The agent may propose work that contradicts a past architectural
decision that exists only in a Slack thread.

**Correct approach**: Add real decisions before running agents on non-trivial work.
Even 3–5 entries covering the most important constraints dramatically improve agent
planning quality.

---

## Workflow anti-patterns

### AP-W1: Skipping demand-triage and jumping straight to implementation

**Symptom**: Agent starts editing files immediately after reading the request, without
running the triage checklist from `skills/demand-triage/SKILL.md`.

**Problem**: Without triage, the agent cannot know whether the task is Small, Medium,
or Large. This determines whether a plan is needed, whether a critic should run, whether
a compliance block is required, and whether checkpoints activate.

**Correct approach**: Always run demand-triage after repo-exploration and before any
code change. A 30-second triage classification prevents wasted planning work on simple
tasks and prevents missing required gates on complex ones.

---

### AP-W2: Treating a single failed attempt as a "stuck" escalation

**Symptom**: Agent escalates to the user or triggers `repeated_failed_fix_loop` after
only one failed fix attempt.

**Problem**: One failure is normal. The `repeated_failed_fix_loop` trigger requires
at least `max_attempts_at_current_tier` (default: 2) attempts that all ended in the
same failure family without material reduction. Escalating too early defeats the purpose
of the validation loop.

**Correct approach**: Follow the three-attempt rule from `skills/error-recovery/SKILL.md`.
Only escalate after at least 2–3 attempts that all exhibit the same dominant failure
signature. See `docs/context-pack-adapters.md` → Recommended runtime rule for the full
`repeated_failed_fix_loop` definition.

---

### AP-W3: Merging role changes into a single context

**Symptom**: A single conversation switches from `feature-planner` to
`application-implementer` work within the same prompt chain.

**Problem**: Each role has a distinct capability ceiling, output contract, and
context isolation requirement. Mixing roles in one context causes the implementer
to inherit planner assumptions without verifying them, and prevents proper handoff
artifact review.

**Correct approach**: Each role change is a separate subagent invocation with a
structured handoff artifact. The implementer reads the planner's output as a
validated input, not a live conversation thread.

---

### AP-W4: Skipping the `DECISIONS.md` contradiction check

**Symptom**: Agent produces a plan that contradicts an existing decision in `DECISIONS.md`
without flagging it.

**Problem**: This is one of the most common ways agent-assisted work silently reverts
prior architectural choices. The contradiction check is mandatory in `docs/operating-rules.md`
and exists precisely to prevent this.

**Correct approach**: Use `bash scripts/decisions-context.sh` to extract a compact
contradiction-check context before planning. Feed the output into the planning step.
If a contradiction is found, surface it immediately as a blocking question before
proposing any implementation.

---

## Security anti-patterns

### AP-S1: Treating advisory gate checks as hard enforcement

**Symptom**: Team adopts a non-claude-code adapter and assumes the gate checks in
`.windsurfrules` or `harness.mdc` are enforced.

**Problem**: All non-claude-code adapters deliver governance as agent instructions.
The agent is told to self-check — but there is no programmatic block. A misconfigured
or misbehaving agent can bypass them.

**Correct approach**: Use CI enforcement (`agent-review.yml`) as the actual backstop.
For high-risk operations, use `execution_mode: supervised` so human approval is
required regardless of the instruction surface.

---

### AP-S2: Using `skip_critic_role: true` for security-sensitive work

**Symptom**: `prompt-budget.yml` globally sets `skip_critic_role: true` to save tokens,
and this applies to tasks that involve auth, permissions, secrets, or data exposure.

**Problem**: The critic role specifically catches design flaws, hidden coupling, and
missing edge cases. For security-sensitive tasks, it is one of the most important
safeguards before user approval.

**Correct approach**: Only skip the critic for tasks where it genuinely adds no value
(formatting, docs sync, deterministic transforms). For Medium/Large tasks touching
security, keep the critic active. The token cost is justified.
