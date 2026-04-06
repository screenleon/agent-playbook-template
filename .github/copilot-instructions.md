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
- Keep reusable guidance in version-controlled markdown instead of chat-only instructions.

## Mandatory workflow

Before any implementation:
1. Discover the codebase (`skills/repo-exploration/SKILL.md`).
2. Read `DECISIONS.md` and project-specific constraints.

After any code change:
3. Run the validation loop (`skills/test-and-fix-loop/SKILL.md`): tests → lint → fix → repeat.
4. Use error recovery (`skills/error-recovery/SKILL.md`) if anything fails.
5. Record decisions in `DECISIONS.md` when applicable.
