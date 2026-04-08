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
- `demand-triage` — classify task scale and adapt workflow intensity
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
Discover → Triage → Plan → Critique → Approve → Implement → Test → Fix → Repeat → Record → Summarize
```

Treat this loop as the **canonical superset**. After Triage, some steps may be simplified or skipped only when explicitly allowed by `docs/agent-playbook.md` and `skills/demand-triage/SKILL.md`.

Every implementation task follows this flow:
1. **Discover** — understand the codebase first (repo-exploration skill)
2. **Triage** — classify task scale (Small/Medium/Large) and adapt workflow intensity (demand-triage skill)
3. **Plan** — select the applicable path explicitly (Small simplification vs. Medium/Large planning path)
4. **Critique** — invoke the critic to challenge the plan before the user sees it (required for Medium/Large planning paths)
5. **Approve** — present plan + critique to the user and wait for explicit approval before implementing when required by checkpoint gates
6. **Implement** — write code following project conventions; state assumptions/constraints/approach before writing code
7. **Test** — run the validation loop (test-and-fix-loop skill)
8. **Fix** — use error-recovery skill if anything fails
9. **Repeat** — iterate until tests pass and code is verified
10. **Record** — update decision log and architecture docs
11. **Summarize** — produce a brief task completion summary for memory and handoff continuity

Before implementation begins, the first response must make workflow selection visible by stating: files/docs read, triage scale, selected path, checkpoint map/checkpoint expectations, and why that path is valid.

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
