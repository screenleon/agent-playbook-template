# Agent Playbook

Read these files before starting work:

1. `docs/operating-rules.md` — mandatory safety, scope, validation, error recovery, and project-specific constraint rules
2. `docs/agent-playbook.md` — routing rules and role definitions
3. `docs/agent-templates.md` — reusable task and prompt templates as optional helpers

Read `docs/adoption-guide.md` when adapting this template to a new repository.
Read `docs/external-practices-notes.md` only when evolving the framework itself.

## Three-layer architecture

### Layer 1: Rules (constraints)

Defined in `docs/operating-rules.md`:
- Safety, scope, and validation rules
- Codebase discovery requirements (repo-aware)
- Validation loop (write → test → fix → repeat)
- Error recovery protocol
- Project-specific constraints (must be filled per repo)
- Decision log expectations

### Layer 2: Skills (capabilities)

Defined in `skills/*/SKILL.md`:
- `repo-exploration` — understand the codebase before coding
- `test-and-fix-loop` — enforce iterative validation after code changes
- `error-recovery` — diagnose and fix compile errors, test failures, runtime issues
- `memory-and-state` — maintain persistent context across sessions
- `feature-planning` — system-level planning before implementation
- `backend-change-planning` — contract-first backend design
- `application-implementation` — general product implementation
- `design-to-code` — screenshot/mockup to code
- `documentation-architecture` — maintainable documentation

### Layer 3: Loop (workflow)

```
Plan → Critique → Approve → Read → Implement → Test → Fix → Repeat → Record
```

Every implementation task follows this flow:
1. **Plan** — use feature-planner for complex work, or confirm scope for simple work
2. **Critique** — invoke the critic to challenge the plan before the user sees it
3. **Approve** — present plan + critique to the user and wait for explicit approval before implementing (mandatory checkpoint)
4. **Read** — discover the codebase (repo-exploration skill)
5. **Implement** — write code following project conventions; state assumptions/constraints/approach before writing code
6. **Test** — run the validation loop (test-and-fix-loop skill)
7. **Fix** — use error-recovery skill if anything fails
8. **Repeat** — iterate until tests pass and code is verified
9. **Record** — update decision log and architecture docs

Core rules:

- Use a planning agent first for cross-module, ambiguous, high-risk, API, DB, auth, or security work.
- Use an application implementer for general product or frontend work that is not primarily backend architecture, pure integration, or image-led UI.
- Use a design-focused agent first for image-led UI implementation.
- Use a documentation-focused agent when the main output is repo rules, architectural notes, onboarding docs, ADRs, runbooks, or API/process documentation.
- Keep reusable instructions in version-controlled files, not only in chat history.
- Prefer specialized agents with clear ownership over one general-purpose agent.
- Never treat code as complete until the validation loop passes.
- Each role runs in its own context (separate invocation). Do not chain roles in one conversation. Pass structured handoff artifacts between roles, not raw history.

Source of truth:

- `docs/operating-rules.md` is the source of truth for safety, scope, validation, and review rules.
- `docs/agent-playbook.md` is the source of truth for role routing and role ownership.
- `docs/agent-templates.md`, `.claude/agents/`, `skills/`, and `.github/copilot-instructions.md` must stay aligned with those two files.
