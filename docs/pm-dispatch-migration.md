# pm-dispatch Migration Boundary

This repository is archived as a portable governance reference. The active
implementation and operational source of truth is `pm-dispatch`.

## Decision

Do not maintain two active implementations of the same agent workflow. Keep
generic methodology here only when it is useful to adopters of other runtimes;
keep executable behavior, runtime schemas, state, and enforcement in
`pm-dispatch`.

The intended direction is:

```text
portable rule / method
        ↓
pm-dispatch brief and policy
        ↓
adapter / hook / gate enforcement
        ↓
evidence and canonical state
```

## Source-of-truth split

| Concern | Active owner | Treatment in this repository |
|---|---|---|
| Safety, prompt-injection, and secret non-disclosure principles | `pm-dispatch` policy/runtime, reconciled with target-project rules | Keep as reference; migrate only the durable invariants |
| Test taxonomy and validation expectations | `pm-dispatch` QA/gate policy | Migrate the MFT/INV/DIR concepts if the gate consumes them |
| Role and workflow methodology | Target project or `pm-dispatch` agent/skill contracts | Keep the portable concepts; do not add another executor implementation |
| Dispatch brief, handover, run, event, and gate schemas | `pm-dispatch/core/schema/` | Do not migrate or extend the template copies |
| Context-pack production and retrieval | `pm-dispatch` context runtime | Do not use this repository's builder as a second production path |
| Adapter hooks, detached lifecycle, memory, and state writes | `pm-dispatch/runtime/`, `hosts/`, and `adapters/` | Do not duplicate here |
| Domain examples (`backend-api`, `frontend-components`, `cloud-infra`) | Adopting project | Keep as examples; migrate only project-relevant rules |

## Generic rules migration inventory

### Migrate or reconcile in pm-dispatch

- `rules/global/prompt-injection.md` — fail-closed handling of untrusted
  instructions and tool output.
- Security baseline invariants from `rules/global/security-baseline.md` — only
  the portable non-disclosure, input-validation, and authorization principles;
  reconcile them with pm-dispatch's existing security and guard contracts.
- `rules/global/test-coverage-spec.md` — MFT/INV/DIR classification and the
  requirement to explain intentionally absent categories, if QA/gate policy
  uses that taxonomy.
- The portable parts of `GCODE-001`, `GCODE-002`, and `GCODE-004` from
  `rules/global/code-quality-baseline.md` — simplicity, explicit assumptions,
  and verifiable success criteria.

### Selectively migrate when a consumer exists

- `alignment-loop` — only if it becomes an explicit pre-brief or pre-gate
  phase in pm-dispatch.
- `ubiquitous-language` — only for projects that provide a glossary and a
  retrieval/injection path.
- `self-reflection` and `observability` concepts — only where pm-dispatch has a
  corresponding evidence or trace consumer.

### Keep here as reference; do not migrate wholesale

- `docs/operating-rules.md`, `docs/agent-playbook.md`, and the adapter guides.
  They describe a portable template and would duplicate pm-dispatch's runtime
  contracts if copied unchanged.
- `rules/domain/*.md`. These are reusable examples, not universal pm-dispatch
  policy. Target repositories should opt in to the relevant domain rules.
- `docs/schemas/*`. pm-dispatch owns the runtime schemas. In particular, the
  template context-pack and brief schemas are not replacements for
  `pm-dispatch/core/schema/`.
- Template-only adoption, budget, and eval documentation that has no active
  pm-dispatch consumer.

## Migration acceptance criteria

The archive boundary is complete when:

1. New runtime or schema work is rejected in this repository.
2. Every generic rule selected for migration has one pm-dispatch owner and one
   enforcement or evidence consumer.
3. No pm-dispatch production path reads the template's schemas or context-pack
   builder as an implicit second source of truth.
4. The template's local lint and tooling checks remain green for historical
   reference use.

## Current audit status

This document is the boundary contract, not evidence that every candidate rule
has already migrated. The active owner/consumer audit is maintained in
`pm-dispatch/docs/audits/agent-playbook-reconciliation.md`. A candidate remains
`defer` until that audit names both an active owner and an enforcement or
evidence consumer.

## Ownership note

This document records the boundary, not a claim that every listed rule has
already been copied into pm-dispatch. The migration itself belongs in the
pm-dispatch repository and must follow its schema, policy, and test contracts.
