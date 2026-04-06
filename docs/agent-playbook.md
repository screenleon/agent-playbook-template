# Agent Playbook

## Repository asset map

- Global entrypoint: `AGENTS.md`
- Project subagents: `.claude/agents/*.md`
- Reusable templates: `docs/agent-templates.md`
- Reusable skills: `skills/*/SKILL.md`
- Repo-wide Copilot instructions: `.github/copilot-instructions.md`

## Default routing

### Use the planning agent first when

- a request impacts more than one module
- a request changes API contracts, schemas, migrations, events, or background jobs
- a request touches auth, permissions, audit, uploads, security, or notifications
- a request is still ambiguous and needs scope, order, or risk clarification
- a request is driven by screenshots or mockups and also changes flow or state

### Use specialist agents directly when

- backend contract and domain work is isolated
- image-led UI implementation is isolated
- integration work is mostly wiring existing pieces together
- final review is focused on bugs, security, and regressions

## Suggested workflow

### New feature

`feature-planner` -> `backend-architect` and/or `ui-image-implementer` -> `integration-engineer` -> `risk-reviewer`

### High-risk backend change

`feature-planner` -> `backend-architect` -> `risk-reviewer`

### Image-led UI change

If it is visual only:

`ui-image-implementer` -> `risk-reviewer`

If it also changes logic or flow:

`feature-planner` -> `ui-image-implementer` -> `integration-engineer` -> `risk-reviewer`

## Ownership principles

- Planning agents define scope, order, dependencies, and validation.
- Implementation agents stay inside their domain and avoid unnecessary expansion.
- Integration agents close loops across state, navigation, side effects, and data flow.
- Review agents lead with findings, not summaries.

## Maintenance principles

- Keep root guidance short and stable.
- Put details in focused docs, agents, and skills.
- Promote repeated prompts into reusable templates.
- Keep templates generic unless a repository-specific constraint truly matters.
