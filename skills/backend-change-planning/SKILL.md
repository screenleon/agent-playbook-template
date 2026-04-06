---
name: backend-change-planning
description: Use when backend work requires contract-first thinking, schema changes, permission checks, side-effect analysis, or test planning.
---

# Backend Change Planning

Use this skill before implementing non-trivial backend changes.

## Check in this order

1. contract changes
2. schema and migration changes
3. query and repository impact
4. validation and error flow
5. permission and ownership checks
6. audit and other side effects
7. tests

## Expected output

1. contract impact
2. schema and migration impact
3. permission and ownership impact
4. audit and side effects
5. validation and error handling
6. required tests

This checklist should stay aligned with `.claude/agents/backend-architect.md` and `docs/agent-templates.md`.
