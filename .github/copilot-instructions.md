# Repository instructions for AI coding agents

- Read `AGENTS.md` first.
- **Agent-deference principle**: this template only adds rules the agent tool does not already provide natively. Capabilities the agent handles out of the box (e.g., built-in safety rails, tool routing, output formatting) should not be re-specified here. See `docs/operating-rules.md` → Agent-deference principle.
- **Trust level**: the project defaults to `semi-auto`. Override with `supervised` or `autonomous` as needed via `prompt-budget.yml` → `execution_mode`. For unattended execution, use `execution_mode: autonomous` and configure `autonomous_mode.*` explicitly. See `docs/operating-rules.md` → Trust level and Autonomous execution mode.
- **Profile-aware loading**: read `prompt-budget.yml` → `budget.profile` first. At `minimal`, use `docs/rules-quickstart.md` as your complete Layer 1 — do not load the full operating-rules.md or agent-playbook.md unless a specific lookup is needed.
- Treat named roles such as `feature-planner` or `risk-reviewer` as conceptual roles. If the tool cannot spawn named subagents, use the matching prompt template or local docs instead.
- Follow `docs/operating-rules.md` for safety, scope, and validation rules.
- Keep outputs concise by default. Expand only when risk, ambiguity, or the user request requires more detail.
- Check `prompt-budget.yml` at the repo root for `execution_mode` (`supervised`, `semi-auto`, or `autonomous`) before acting on checkpoint gates. See `docs/operating-rules.md` → Autonomous execution mode for gate behavior per mode.
- Use `feature-planner` for cross-module, ambiguous, high-risk, contract-changing, database, auth, security, or image-led flow changes. Bounded application changes may go directly to implementation when `docs/agent-playbook.md` routes them that way.
- Use `backend-architect` for backend contract and domain work.
- Use `application-implementer` for general product or frontend implementation work.
- Use `ui-image-implementer` for screenshot-driven or mockup-driven UI work.
- Use `integration-engineer` to close wiring and flow gaps.
- Use `documentation-architect` for repository rules, ADRs, onboarding docs, and other durable documentation.
- Use `risk-reviewer` before finalizing behavior-changing or high-risk work.
- Use `critic` after a plan or proposal is produced, before user approval, to challenge design quality.
- Keep reusable guidance in version-controlled markdown instead of chat-only instructions.
- Each role should run in a separate context (subagent invocation). Same-role intent-mode changes may stay in one context when the workflow allows it. Pass structured handoff artifacts between roles, not raw conversation history.
- When loading instruction files, follow the four-layer loading order (static rules → stable skills → project state → volatile context) to maximize prompt cache hits. See `skills/prompt-cache-optimization/SKILL.md` for details.
- Follow layered configuration precedence from `docs/operating-rules.md`: Project Context → Domain Rules → Global Rules.

## Mandatory workflow

Before any implementation:
1. Discover the codebase (`skills/repo-exploration/SKILL.md`).
2. For first entry in a new repository, follow the profile-aware initialization rule: at `minimal`, perform the manual scan path from `docs/rules-quickstart.md`; at `standard`/`full`, run `skills/on-project-start/SKILL.md`.
3. Classify the task scale (`skills/demand-triage/SKILL.md`): Small, Medium, or Large.
4. Follow the compliance-block rules from `docs/operating-rules.md` → Mandatory first-response compliance block. At `semi-auto`, Medium/Large tasks require it. At `autonomous`, it is optional.
5. Read `DECISIONS.md` and check for contradictions. For legacy modules, also search `DECISIONS_ARCHIVE.md` if it exists.
6. State assumptions, constraints, and proposed approach before writing code.
7. For behavior-changing work, define tests first per TDAI requirement in `docs/operating-rules.md`.

After planning (for Medium/Large work):
8. Invoke `critic` to challenge the plan. At `supervised`, present plan + critique to the user and wait for approval. At `semi-auto`, wait only when the plan-approval gate is active for the current task (for example Large or high-risk work). At `autonomous`, the critic still runs by default; plan approval auto-proceeds by default, but remains STOP behavior when `autonomous_mode.auto_proceed_on_plan: false` is set. `skip_critic_role: true` controls whether the critic runs at all.

After any code change:
9. Run the validation loop (`skills/test-and-fix-loop/SKILL.md`) — this runs autonomously (auto-fix without human approval). For Small tasks, run targeted tests only.
10. Use error recovery (`skills/error-recovery/SKILL.md`) if anything fails. Escalate after 3 consecutive failures unless autonomous mode explicitly relaxes that stop via `autonomous_mode.halt_on_stuck_escalation: false`.
11. Record decisions in `DECISIONS.md` when applicable — unless `prompt-budget.yml` → `decision_log.policy: example_only`, in which case record in the task summary or handoff artifact instead and do not write to `DECISIONS.md`.
12. If architecture changed, update ADRs (or decision log when ADR directory does not exist) in the same task.
13. If scope expands beyond the plan: at `supervised`/`semi-auto` trust level, STOP and present the expanded scope when the scope-expansion gate is active. At `autonomous`, log an ADVISORY and continue only when the expansion remains within original intent and `autonomous_mode.auto_proceed_on_scope_expansion` is enabled; if it adds an unrelated module, STOP.
14. Before final output, run self-reflection (`skills/self-reflection/SKILL.md`) using the required rubric depth for the task scale.
15. Produce the final output using the role-appropriate format from `docs/operating-rules.md`: Deliverable template for non-review roles; findings-first review output for `risk-reviewer` and `critic`. For Small tasks, a concise final summary may serve as the streamlined deliverable when the Small-task output contract allows it.
16. Emit trace output per `skills/observability/SKILL.md` (Small tasks may keep this minimal and inline).
17. Produce a task completion summary (`docs/agent-templates.md` → Task completion summary). At `semi-auto`/`autonomous` trust level for Small tasks, a brief summary suffices and may overlap with the streamlined deliverable.
18. Include the feedback-loop mini retrospective required by `docs/operating-rules.md`.
