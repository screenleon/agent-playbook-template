# Repository instructions for AI coding agents

- Read `AGENTS.md` first.
- Treat named roles such as `feature-planner` or `risk-reviewer` as conceptual roles. If the tool cannot spawn named subagents, use the matching prompt template or local docs instead.
- Follow `docs/operating-rules.md` for safety, scope, and validation rules.
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

## Mandatory workflow

Before any implementation:
1. Discover the codebase (`skills/repo-exploration/SKILL.md`).
2. Classify the task scale (`skills/demand-triage/SKILL.md`): Small, Medium, or Large. Adapt workflow intensity accordingly.
3. In the first response, publish a compliance block: files/docs read, `[SCALE: ...]` + reason, selected workflow path, and expected checkpoints.
4. Read `DECISIONS.md` and project-specific constraints. For tasks involving legacy modules, also search `DECISIONS_ARCHIVE.md` if it exists.
5. Check whether the proposed work contradicts any existing decision. If no match in active decisions, search archive before concluding no prior decision exists. If contradiction found, STOP and present it.
6. State assumptions, constraints, and proposed approach before writing code. For Small tasks, this may be inline (1-2 sentences), but it is still mandatory.

After planning (for Medium/Large work):
7. Invoke `critic` to challenge the plan before presenting to user.
8. Present plan + critique to the user and wait for approval before implementing.

After any code change:
9. Run the validation loop (`skills/test-and-fix-loop/SKILL.md`): tests → lint → fix → repeat. For Small tasks, run targeted tests only.
10. Use error recovery (`skills/error-recovery/SKILL.md`) if anything fails.
11. Record decisions in `DECISIONS.md` when applicable.
12. If scope expands beyond the original plan, STOP and present the expanded scope for approval.
13. Produce a task completion summary (`docs/agent-templates.md` → Task completion summary).
