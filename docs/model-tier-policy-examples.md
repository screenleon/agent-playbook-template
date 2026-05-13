# Model Tier Policy Examples

This is a reference implementation for adopters who want a concrete policy for
the optional abstract model-tier routing described in
`docs/operating-rules.md` -> "Abstract model-tier routing".

It is not a normative rule for this template. Copy and adapt it only when your
runtime or orchestration layer can choose model tiers explicitly.

## Core Boundary

Model tiers are abstract, vendor-neutral routing intents. Keep concrete provider
model IDs in adapter config, `prompt-budget.local.yml`, or runtime settings, not
in source-of-truth documentation.

Tier escalation retries the same role and task at a deeper tier. It does not
replace trust-level checkpoints, role handoffs, approval gates, or the default
stuck-escalation stop after 3 failed attempts.

## Tier Definitions

| Tier | Use for | Do not use for |
|---|---|---|
| `fast` | Low-latency, low-cost mechanical tasks: formatting, search, simple lookup, deterministic transforms | Reasoning-heavy work, review, planning, implementation, ambiguous diagnosis |
| `balanced` | Default for agent work: review, analysis, planning, implementation, synthesis, dispatch, bounded execution | Novel architecture that clearly meets a `deep` signal |
| `deep` | Novel cross-cutting architecture, high-stakes hard-to-reverse decisions, very large context analysis, ambiguous or unprecedented problems | Routine review gates, deterministic tasks, dispatch, executor work, ordinary docs sync |

## Default Policy

- Default tier: `balanced`.
- All spawned reviewer, planner, and implementer agents start at `balanced`
  unless the session is already explicitly elevated under this policy.
- Multi-reviewer gates always use `balanced` for every reviewer agent and for
  the synthesis step. Reviewer work is bounded and scoped, not novel
  architecture.
- Dispatch and executor agents always use `balanced`.
- PM and planning agents inherit the caller's tier. They may use `deep` only
  when the current session has already been elevated or the user confirms a new
  escalation.
- `fast` is reserved for mechanical helper work and should not own substantive
  agent reasoning.
- `deep` requires explicit user confirmation before use.

## Tier Decision Table

| Signal | Tier |
|---|---|
| Formatting, copy edits, deterministic file transforms | `fast` |
| Search, simple lookup, inventory, or path validation | `fast` |
| Ordinary implementation with clear scope | `balanced` |
| Code review or multi-reviewer gate | `balanced` |
| Reviewer synthesis | `balanced` |
| Dispatch or executor orchestration | `balanced` |
| PM or planning work in a normal session | `balanced` |
| PM or planning work in an already elevated session | caller tier |
| Novel cross-cutting architecture | ask before `deep` |
| High-stakes, hard-to-reverse decision | ask before `deep` |
| Very large context analysis across 10+ interdependent files | ask before `deep` |
| Ambiguous or unprecedented problem with no clear existing pattern | ask before `deep` |

## Deep Escalation Policy

Escalate to `deep` only when the task meets at least one `deep` signal:

- Novel cross-cutting architecture.
- High-stakes decision that is hard to reverse.
- Very large context analysis across 10 or more interdependent files.
- Ambiguous or unprecedented problem where the normal repo patterns are not
  enough to choose safely.

Before escalating, the agent or runtime must:

1. State why `deep` is needed for this specific task.
2. Warn that `deep` is expected to cost roughly 3-5x more than `balanced`.
3. Give the user a clear choice to approve `deep` or continue on `balanced`.
4. Continue on `balanced` unless the user explicitly approves escalation.

## Ask-Before-Use Script

Use this script template before any `deep` escalation:

```text
This task appears to meet the `deep` tier signal: <specific signal>.

Why: <one or two sentences tied to the current task, files, or decision>.

Cost note: `deep` is expected to cost roughly 3-5x more than `balanced`.

Choose one:
1. Approve `deep` for this task.
2. Continue on `balanced` and accept a narrower or slower analysis path.
```

## Example `model_routing` Shape

```yaml
model_routing:
  enabled: true
  policy:
    default_tier: balanced
    escalation_tier: deep
    require_confirmation_for:
      - deep
    cost_warning:
      deep: roughly 3-5x balanced
```

This example intentionally omits provider and model identifiers. Put those
runtime-specific mappings in adapter config, `prompt-budget.local.yml`, or
runtime settings.
