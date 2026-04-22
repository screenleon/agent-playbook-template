# Architecture Overview

Architecture for this repository. Replace with your own module map and data flow when adopting.

## Module map

| Directory / module | Purpose |
|-------------------|---------|
| `AGENTS.md` | Root entrypoint and profile-aware loading order |
| `docs/` | Source-of-truth governance docs, workflow rules, templates, and guides |
| `skills/` | Reusable execution skills (planning, implementation, validation, recovery, memory) |
| `rules/global/` | Cross-project rules layer (security baseline starter included) |
| `rules/domain/` | Domain-specific rules layer |
| `project/project-manifest.md` | Project-local constraints and boundary declarations |
| `scripts/` | Documentation lint, layered-rule lint, trace analytics, conflict-check, eval runner/scorer |
| `.github/workflows/` | CI execution for governance and agent review checks |
| `DECISIONS.md` / `DECISIONS_ARCHIVE.md` | Active and archived architectural/behavioral decisions |
| `prompt-budget.yml` | Execution mode, budget profile, and role/skill enablement controls |
| `examples/` | Reference operating profiles and usage patterns |
| `evals/` | Adapter-neutral governance evaluation suite — canonical fixtures + runner |

## Data flow

Primary flow for repository usage:

1. User request enters through agent runtime.
2. Agent reads `AGENTS.md` and resolves profile, execution mode, and any optional abstract model-tier policy from `prompt-budget.yml`.
3. Agent loads rules from `docs/rules-quickstart.md` or `docs/rules-nano.md`, then expands into `docs/operating-rules.md` and `docs/agent-playbook.md` when profile requires it.
4. Agent loads applicable `skills/*/SKILL.md` files for discovery, triage, implementation, and validation.
5. Agent performs repository changes and records durable decisions in `DECISIONS.md`.
6. Validation loop executes tests/lint and applies error recovery as needed.
7. Governance scripts (`scripts/lint-doc-consistency.sh`, `scripts/lint-layered-rules.sh`) and CI workflows enforce documentation/rule consistency.

## Key interfaces and contracts

- `docs/operating-rules.md` — canonical safety/scope/validation contract.
- `docs/agent-playbook.md` — canonical role ownership and routing contract.
- `prompt-budget.yml` — runtime control plane contract for `execution_mode`, `budget.profile`, enabled roles/skills, and optional abstract model-tier routing policy.
- `docs/schemas/handoff-artifact.schema.yaml` — structured handoff artifact contract between roles.
- `docs/schemas/trace.schema.yaml` — adapter-neutral trace contract consumed by `scripts/trace-query.py`, `scripts/score-eval.py`, `scripts/agent-review.sh`, and CI workflows.
- `evals/schema/expected-behavior.schema.yaml` — per-fixture eval contract used by `scripts/score-eval.py`.
- `DECISIONS.md` format — contradiction-check contract used before planning and implementation.

## External service dependencies

| Service | Purpose | Notes |
|---------|---------|-------|
| GitHub Actions | Runs governance and review workflows | Triggered by workflow files in `.github/workflows/` |
| Shell tooling (`bash`, `grep`, `awk`, `sed`) | Executes local lint scripts | Required by `scripts/lint-*.sh` |

## Deployment units

Single documentation/governance repository. Primary execution units are:

- Local agent runtime (interactive development sessions)
- CI workflows for governance and consistency checks

## Known technical debt

- Governance checks are shell-script based; portability to non-POSIX environments relies on CI rather than local parity.
- Trace review uses lightweight YAML heuristics instead of a dedicated schema validator.
