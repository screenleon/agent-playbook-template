# Project Manifest

Project-local boundaries and constraints for this repository.

## Project identity

- Name: agent-playbook-template
- Repository type: documentation and agent-governance template
- Primary language(s): Markdown, YAML, Bash
- Runtime framework(s): GitHub Actions, shell-based local tooling

## Non-negotiable constraints

- Constraint 1: Source of truth for project-local constraints is `project/project-manifest.md`; do not duplicate active repo-specific constraints in `docs/operating-rules.md`.
- Constraint 2: Workflow wording changes must keep `AGENTS.md`, `docs/agent-playbook.md`, `.github/copilot-instructions.md`, and affected skills aligned in the same change, including the `DECISIONS.md` example-only guard when `decision_log.policy: example_only` applies.
- Constraint 3: Governance automation should stay shell-first and runnable in CI without extra language runtimes.
- Constraint 4: `DECISIONS.md` is **example-only** in this template repo. See [DECISIONS.md policy](#decisionsmd-policy) below.

## Build and validation commands

- Build: N/A — no compiled artifact
- Unit tests: N/A — repository uses script-based validation instead of a unit test suite
- Integration tests: `bash scripts/agent-review.sh`
- Lint/static analysis: `bash scripts/lint-layered-rules.sh && bash scripts/lint-doc-consistency.sh && bash scripts/adoption-audit.sh --strict`

## Deployment and operations boundaries

- Environments: local development and GitHub Actions CI
- Release process: documentation and script changes merge through normal pull requests; no automated deploy target
- Incident/rollback rule: revert the offending documentation or script change and re-run governance checks before merge

## Security and compliance boundaries

- Secret handling: never commit credentials; examples must stay synthetic and masked
- Auth/permission model: repository has no runtime auth system; security focus is on instruction safety and secret non-disclosure
- Data classification: public repository content only; no production or customer data belongs here

## Architecture context

- System style (monolith, modular monolith, microservices, etc.): single governance template repository
- Critical integration dependencies: GitHub Actions, bash, grep, awk, markdownlint, agent runtimes that consume repo instructions
- Known technical debt: shell-based validation limits local portability; YAML review uses lightweight parsing rather than a schema engine

## Override notes

- Any project rule that should override domain/global guidance: project manifest owns repo-local constraints and validation commands for this repository.

## DECISIONS.md policy

This repository is a governance template. `DECISIONS.md` exists solely to demonstrate the decision-log format for adopters — it is **not** a live task journal.

**Rules for agents working in this repository:**

- Read `DECISIONS.md` for contradiction checks only (as normal).
- Do **not** auto-append task decisions to `DECISIONS.md`.
- When a decision would normally be captured, record it in the task completion summary, handoff artifact, or trace file instead.
- Writes to `DECISIONS.md` are **only allowed** when (a) the user explicitly requests an update to the example content, or (b) the change targets the template's own decision-format or schema.

This overrides the `Automatic decision capture` and `Mandatory audit log` rules in `docs/operating-rules.md`.

The active policy value is set in `prompt-budget.yml` → `decision_log.policy: example_only`. When adopting this template for a real project, change that value to `normal`.

## Override annotations

Use this format when project rules override base rules:

`Overrides: <base-rule-id> -> <project-rule-id>`

Example:

`Overrides: API-002 -> PROJECT-API-001`

## Override registry

| Base Rule ID | Project Rule ID | Reason | Status |
|---|---|---|---|
| API-002 | PROJECT-TEMPLATE-001 | Template repo keeps repo-local constraints in the manifest instead of the generic operating-rules placeholder | active |

> **PROJECT-TEMPLATE-002 (project-local governance policy — no base layered rule ID)**: `DECISIONS.md` is example-only in this template repo. Automatic decision capture and autonomous audit-log writes to `DECISIONS.md` are disabled. This is not an override of a defined layered rule; it is a project-level behavioral policy enforced via `prompt-budget.yml` → `decision_log.policy: example_only` and documented in the [DECISIONS.md policy](#decisionsmd-policy) section. When adopting this template for a real project, set `policy: normal` to restore standard capture behavior.

## Workspace boundaries

Define path-based domain rule masking. Leave empty or remove this section to load all domain rules unconditionally.

| Path glob | Active domain rules | Masked domain rules |
|---|---|---|
| `rules/domain/**` | backend-api, frontend-components, cloud-infra |  |
| `scripts/**` | cloud-infra | backend-api, frontend-components |
| `docs/**` |  |  |

## MCP tool declarations

Declare MCP (Model Context Protocol) tools used by this project. Leave empty or remove this section if MCP is not used. See `skills/mcp-validation/SKILL.md` for the validation workflow.

| Tool name | Server / endpoint | Fallback builtin | Notes |
|---|---|---|---|
| N/A | N/A | builtin filesystem and shell tools | No MCP tools are configured in this repository |
