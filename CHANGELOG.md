# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added

- **Human checkpoint gates** (`docs/operating-rules.md`) — mandatory STOP points where agents must wait for user approval: after planning (before implementation), on scope expansion, on decision contradiction, and on stuck escalation. Includes checkpoint output format and recommended mid-implementation review gate.
- **Structured output and anti-drift rules** (`docs/operating-rules.md`) — mandatory structured preamble (assumptions, constraints, proposed approach) before any implementation; context anchor protocol for multi-step tasks; output completeness checks requiring "N/A" instead of silent omission.
- **Contradiction detection protocol** (`docs/operating-rules.md`, `skills/memory-and-state/SKILL.md`) — agents must check `DECISIONS.md` before making decisions and STOP if a conflict is found, presenting both the existing decision and the proposed change.
- **Automatic decision capture triggers** (`docs/operating-rules.md`) — expanded list of events that require `DECISIONS.md` entries: new technology/library, schema/contract changes, permission model changes, architectural boundary changes, tradeoffs.
- **Context anchor protocol** (`skills/memory-and-state/SKILL.md`) — structured format for tracking objective, current step, completed work, remaining work, and active constraints during multi-step tasks.
- **`DECISIONS.md` template** — version-controlled decision log template at repo root with example format and usage instructions.
- **Module decomposition guide** (`skills/feature-planning/SKILL.md`) — concrete method for tracing user actions through call chains, listing touched boundaries, marking shared dependencies, and producing a module impact table.
- **Validation criteria guide** (`skills/feature-planning/SKILL.md`) — structured approach for defining test scenarios: happy path, edge cases, error paths, permission boundaries, regression anchors, and integration verification, with table output format.
- **Risk assessment guide** (`skills/feature-planning/SKILL.md`) — risk evaluation framework with likelihood/impact/mitigation/owner for each risk, plus common risk categories (data loss, breaking changes, performance, security, rollback difficulty).
- **Early risk review** (`skills/feature-planning/SKILL.md`, `docs/agent-playbook.md`) — risk-reviewer can now be invoked during planning phase for high-risk plans before user approval, not only as final review.
- **Risk-reviewer dual mode** (`.claude/agents/risk-reviewer.md`, `docs/agent-templates.md`) — Mode 1: plan risk assessment during planning; Mode 2: final implementation review after coding.
- **Automatic documentation maintenance** (`skills/documentation-architecture/SKILL.md`) — triggers and actions for auto-updating `DECISIONS.md`, `ARCHITECTURE.md`, and project-specific constraints as a side effect of code changes. Includes documentation sync check.
- **`ARCHITECTURE.md` template** (`skills/documentation-architecture/SKILL.md`) — canonical structure: module map, key interfaces, data flow, external dependencies, known technical debt.

### Changed

- **Workflow loop** (`AGENTS.md`, `docs/agent-playbook.md`) — changed from `Plan → Read → Implement → Test → Fix → Repeat → Record` to `Plan → Approve → Read → Implement → Test → Fix → Repeat → Record`. Mandatory user approval gate between planning and implementation.
- **All suggested workflows** (`docs/agent-playbook.md`) — inserted `→ user approval →` step between planning and implementation agents in every multi-agent workflow.
- **High-risk backend workflow** (`docs/agent-playbook.md`) — now includes risk-reviewer plan assessment before user approval and risk-reviewer final review after implementation.
- **Mandatory workflow steps** (`docs/agent-playbook.md`) — added structured preamble requirement and mandatory checkpoint gates section to the workflow preamble.
- **Common preamble** (`docs/agent-templates.md`) — now includes: contradiction check against `DECISIONS.md`, mandatory assumption/constraint/approach statement before solutions, and decision recording after implementation.
- **Feature planner template** (`docs/agent-templates.md`, `.claude/agents/feature-planner.md`, `skills/feature-planning/SKILL.md`) — added pre-planning checklist, module decomposition guide, validation criteria table, risk assessment table with likelihood/impact/mitigation, implementation ordering rules, early risk review trigger, output completeness verification, and mandatory STOP gate.
- **Backend architect template** (`docs/agent-templates.md`, `.claude/agents/backend-architect.md`) — added structured preamble, contradiction check, completeness verification, STOP gate for high-risk changes, and decision recording.
- **Application implementer template** (`docs/agent-templates.md`, `.claude/agents/application-implementer.md`) — added structured preamble, contradiction check, scope expansion STOP gate, and decision recording.
- **Integration engineer template** (`docs/agent-templates.md`, `.claude/agents/integration-engineer.md`) — added structured preamble, contradiction check, context anchor for long tasks, and decision recording.
- **Risk reviewer template** (`docs/agent-templates.md`, `.claude/agents/risk-reviewer.md`) — added dual-mode operation (plan assessment + final review), decision log compliance check, documentation sync check, completeness verification, and contradiction flagging.
- **Documentation architect** (`docs/agent-templates.md`, `.claude/agents/documentation-architect.md`, `skills/documentation-architecture/SKILL.md`) — expanded from basic checklist to full automatic maintenance responsibilities (DECISIONS.md, ARCHITECTURE.md, constraints) with sync check and writing guidelines.
- **Application implementation skill** (`skills/application-implementation/SKILL.md`) — expanded from 5-item checklist to full guide with implementation guidelines, error handling expectations, and common mistakes to avoid.
- **Backend change planning skill** (`skills/backend-change-planning/SKILL.md`) — expanded from 7-item list to detailed guide with migration safety rules, query impact checks, implementation ordering, and common backend mistakes checklist.
- **Design-to-code skill** (`skills/design-to-code/SKILL.md`) — expanded each breakdown step with concrete details (what to look for, how to map to project tokens), added implementation guidelines (reuse, tokens, mobile-first, accessibility), and common mistakes.
- **Memory and state skill** (`skills/memory-and-state/SKILL.md`) — expanded with context anchor protocol, contradiction detection process, additional write triggers (technology introduced, schema changed, tradeoff made), and stronger enforcement language for mandatory decision log reads.
- **`documentation-architect` role** (`docs/agent-playbook.md`) — added responsibility for automatic maintenance of DECISIONS.md, ARCHITECTURE.md, and project-specific constraints.
- **`risk-reviewer` role** (`docs/agent-playbook.md`) — added early risk assessment capability during planning phase for high-risk work.
- **Copilot instructions** (`.github/copilot-instructions.md`) — expanded mandatory workflow from 5 to 9 steps including contradiction check, structured preamble, plan approval, decision recording, and scope expansion gate.

---

## [0.3.0] - 2026-04-06

### Added

- **Three-layer architecture** (`AGENTS.md`) — explicit model of Rules / Skills / Loop to frame all agent work.
- **Codebase discovery requirement** (`docs/operating-rules.md`) — mandatory steps before coding: read related files, identify existing patterns, follow repo conventions, check dependency graph, read project-specific constraints.
- **Mandatory validation loop** (`docs/operating-rules.md`) — write → test → fix → repeat cycle enforced for every code change. Never treat a change as done until verification passes.
- **Error recovery protocol** (`docs/operating-rules.md`) — structured triage: read full error, identify root cause, fix minimally, re-verify, escalate after 3 failed attempts.
- **Project-specific constraints section** (`docs/operating-rules.md`) — templated section teams must fill with concrete, repo-specific rules (e.g., "use raw SQL", "no ORM", "pricing uses JSONB").
- **Decision log guidance** (`docs/operating-rules.md`) — defines `DECISIONS.md` format and when agents must read or append it.
- **New skill: `repo-exploration`** — structured codebase discovery (structural inventory, pattern identification, dependency graph, constraint check).
- **New skill: `test-and-fix-loop`** — enforces the validation loop with a flowchart, rules, commands for common stacks, and anti-patterns.
- **New skill: `error-recovery`** — error triage protocol with classification table, 6-step recovery process, escalation template, and anti-patterns.
- **New skill: `memory-and-state`** — three-layer persistent memory model: decision log, architecture memory, session-scoped working memory.
- **Common preamble** (`docs/agent-templates.md`) — repo-aware mandatory steps added to every agent prompt: read rules, read DECISIONS.md, discover codebase, run validation loop, use error recovery.
- **Mandatory workflow section** (`.github/copilot-instructions.md`) — explicit five-step workflow all Copilot agents must follow before and after implementation.

### Changed

- **`docs/agent-playbook.md`** — added three-layer architecture overview at top; added mandatory steps (discover, validate, recover, record) that apply to all suggested workflows.
- **`docs/agent-templates.md`** — all agent templates (feature-planner, backend-architect, application-implementer, integration-engineer, risk-reviewer) now include repo discovery steps before implementation and validation steps after.
- **`docs/adoption-guide.md`** — expanded with `Critical first customization` section (project-specific constraints with good/bad examples, validation commands format, decision log bootstrap, architecture overview template) and quarterly maintenance guidance.
- **`AGENTS.md`** — rewritten to describe the three-layer architecture and expose the full `Plan → Read → Implement → Test → Fix → Repeat → Record` workflow loop.

---

## [0.2.0] - 2026-04-06

### Added

- **`docs/adoption-guide.md`** — step-by-step guide for adapting the template to a new repository.
- **`docs/operating-rules.md`** — safety rails, scope control, validation expectations, review expectations, and tool usage boundaries.
- **New Claude agent: `application-implementer`** (`.claude/agents/application-implementer.md`) — owns general product and frontend implementation work.
- **New Claude agent: `documentation-architect`** (`.claude/agents/documentation-architect.md`) — owns repo instructions, onboarding docs, ADRs, and runbooks.
- **New skill: `application-implementation`** — checklist for ordinary application changes.
- **New skill: `documentation-architecture`** — checklist for documentation-primary deliverables.
- **Review prompt file** (`.github/prompts/review-folder-git-status.prompt.md`) — reusable prompt for folder-scoped git status review.
- **`LICENSE`** — MIT license.

### Changed

- **`AGENTS.md`** — added source-of-truth and precedence rules.
- **`README.md`** — expanded significantly with three-layer description, role table, skill list, workflow examples, and adoption steps.
- **`docs/agent-playbook.md`** — added ownership principles, maintenance principles, source-of-truth and precedence hierarchy, tool portability guidance, and expanded workflow section.
- **`docs/agent-templates.md`** — added documentation-architect prompt template.
- **`skills/backend-change-planning/SKILL.md`** — clarified alignment note with playbook source of truth.
- **`skills/feature-planning/SKILL.md`** — added alignment note.
- **`.github/copilot-instructions.md`** — updated role routing rules.

---

## [0.1.0] - 2026-04-06

### Added

Initial release of the agent playbook template.

- **`AGENTS.md`** — root entrypoint listing mandatory files and core routing rules.
- **`docs/agent-playbook.md`** — role definitions, default routing logic, and suggested workflows for common task types.
- **`docs/agent-templates.md`** — reusable prompt templates for task intake, feature-planner, backend-architect, application-implementer, UI-image-implementer, and integration-engineer.
- **`docs/external-practices-notes.md`** — notes on practices from OpenAI, Anthropic, and GitHub Copilot that influenced this template.
- **Claude agent definitions** (`.claude/agents/`):
  - `feature-planner.md`
  - `backend-architect.md`
  - `ui-image-implementer.md`
  - `integration-engineer.md`
  - `risk-reviewer.md`
- **GitHub Copilot instructions** (`.github/copilot-instructions.md`) — repo-scoped routing rules for Copilot.
- **Reusable skills** (`skills/`):
  - `feature-planning/SKILL.md`
  - `backend-change-planning/SKILL.md`
  - `design-to-code/SKILL.md`
- **`README.md`** — project overview.
- **`.gitignore`** — standard ignores.

---

[0.3.0]: https://github.com/screenleon/agent-playbook-template/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/screenleon/agent-playbook-template/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/screenleon/agent-playbook-template/releases/tag/v0.1.0
