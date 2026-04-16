# Architecture Overview

> **Adopter note**: This file documents the template repository itself. When adopting this template into a product repository, replace module names and data flow with your actual system.
>
> Agents read this file before working on unfamiliar modules (see `skills/memory-and-state/SKILL.md` → Architecture memory). When it is missing or stale, agents lose structural context and may make incorrect assumptions.
>
> Keep this file updated when module boundaries, governance flows, or validation automation change.

## Module map

| Directory / module | Purpose |
|-------------------|---------|
| `AGENTS.md` | Root entrypoint and profile-aware loading order |
| `docs/` | Source-of-truth governance docs, workflow rules, templates, and guides |
| `skills/` | Reusable execution skills (planning, implementation, validation, recovery, memory) |
| `rules/global/` | Cross-project rules layer |
| `rules/domain/` | Domain-specific rules layer |
| `project/project-manifest.md` | Project-local constraints and boundary declarations |
| `scripts/` | Documentation and layered-rule lint automation |
| `.github/workflows/` | CI execution for governance and agent review checks |
| `DECISIONS.md` / `DECISIONS_ARCHIVE.md` | Active and archived architectural/behavioral decisions |
| `prompt-budget.yml` | Execution mode, budget profile, and role/skill enablement controls |
| `examples/` | Reference operating profiles and usage patterns |

## Data flow

Primary flow for repository usage:

1. User request enters through agent runtime.
2. Agent reads `AGENTS.md` and resolves profile from `prompt-budget.yml`.
3. Agent loads rules from `docs/rules-quickstart.md` or `docs/rules-nano.md`, then expands into `docs/operating-rules.md` and `docs/agent-playbook.md` when profile requires it.
4. Agent loads applicable `skills/*/SKILL.md` files for discovery, triage, implementation, and validation.
5. Agent performs repository changes and records durable decisions in `DECISIONS.md`.
6. Validation loop executes tests/lint and applies error recovery as needed.
7. Governance scripts (`scripts/lint-doc-consistency.sh`, `scripts/lint-layered-rules.sh`) and CI workflows enforce documentation/rule consistency.

## Key interfaces and contracts

- `docs/operating-rules.md` — canonical safety/scope/validation contract.
- `docs/agent-playbook.md` — canonical role ownership and routing contract.
- `prompt-budget.yml` — runtime control plane contract for `execution_mode`, `budget.profile`, and enabled roles/skills.
- `docs/schemas/handoff-artifact.schema.yaml` — structured handoff artifact contract between roles.
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

- Architectural docs are now filled for the template repo, but adopters still need to replace this file with their repository-specific module map and flow.
- Governance checks are shell-script based; portability to non-POSIX environments relies on CI rather than local parity.
