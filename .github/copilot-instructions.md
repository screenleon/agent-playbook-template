# Repository instructions for AI coding agents

- Read `AGENTS.md` first.
- Treat named roles such as `feature-planner` or `risk-reviewer` as conceptual roles. If the tool cannot spawn named subagents, use the matching prompt template or local docs instead.
- Follow `docs/operating-rules.md` for safety, scope, and validation rules.
- Check `prompt-budget.yml` at the repo root for `execution_mode` (`supervised` or `autonomous`) before acting on checkpoint gates. See `docs/operating-rules.md` → Autonomous execution mode for gate behavior per mode.
- Use `feature-planner` for cross-module, ambiguous, contract, database, auth, security, or image-led flow changes.
- Use `backend-architect` for backend contract and domain work.
- Use `application-implementer` for general product or frontend implementation work.
- Use `ui-image-implementer` for screenshot-driven or mockup-driven UI work.
- Use `integration-engineer` to close wiring and flow gaps.
- Use `documentation-architect` for repository rules, ADRs, onboarding docs, and other durable documentation.
- Use `risk-reviewer` before finalizing behavior-changing or high-risk work.
- Use `critic` after a plan or proposal is produced, before user approval, to challenge design quality.
- Keep reusable guidance in version-controlled markdown instead of chat-only instructions.
- Each role should run in a separate context (subagent invocation). Pass structured handoff artifacts between roles, not raw conversation history.
- When loading instruction files, follow the four-layer loading order (static rules → stable skills → project state → volatile context) to maximize prompt cache hits. See `skills/prompt-cache-optimization/SKILL.md` for details.

## Mandatory workflow

Before any implementation:
1. Discover the codebase (`skills/repo-exploration/SKILL.md`).
2. Classify the task scale (`skills/demand-triage/SKILL.md`): Small, Medium, or Large.
3. Publish a compliance block (see `docs/operating-rules.md` → Mandatory first-response compliance block).
4. Read `DECISIONS.md` and check for contradictions. For legacy modules, also search `DECISIONS_ARCHIVE.md` if it exists.
5. State assumptions, constraints, and proposed approach before writing code.

After planning (for Medium/Large work):
6. Invoke `critic` to challenge the plan; present plan + critique to user; wait for approval.

After any code change:
7. Run the validation loop (`skills/test-and-fix-loop/SKILL.md`). For Small tasks, run targeted tests only.
8. Use error recovery (`skills/error-recovery/SKILL.md`) if anything fails.
9. Record decisions in `DECISIONS.md` when applicable.
10. If scope expands beyond the plan, STOP and present the expanded scope for approval.
11. Produce a task completion summary (`docs/agent-templates.md` → Task completion summary).
