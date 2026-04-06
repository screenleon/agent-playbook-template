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

## First customization pass

Edit these items immediately:

- repository module names
- safety rails
- validation expectations
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
