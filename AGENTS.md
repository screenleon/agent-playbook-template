# Agent Playbook

Read these files before starting work:

1. `docs/agent-playbook.md` — routing rules for planner, implementer, integrator, reviewer
2. `docs/agent-templates.md` — reusable task and prompt templates
3. `docs/external-practices-notes.md` — supporting patterns from external tooling ecosystems

Core rules:

- Use a planning agent first for cross-module, ambiguous, high-risk, API, DB, auth, or security work.
- Use a design-focused agent first for image-led UI implementation.
- Keep reusable instructions in version-controlled files, not only in chat history.
- Prefer specialized agents with clear ownership over one general-purpose agent.
