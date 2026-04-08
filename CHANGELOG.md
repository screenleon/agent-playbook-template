# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Changed

- No changes yet.

---

## [0.6.0] - 2026-04-09

### Added

- **Memory lifecycle management** (`skills/memory-and-state/SKILL.md`) — added decision archive rules (when/how to move stale entries to `DECISIONS_ARCHIVE.md`), selective read strategy (tiered reading table for decisions, architecture memory, session memory), session memory hygiene (promotion rule, cleanup cadence), and memory health indicators (thresholds and actions).
- **Decision archive lifecycle** (`docs/operating-rules.md`) — added archive lifecycle subsection under decision log guidance; expanded mandatory read-before-write to include archive search for legacy module tasks.
- **Archive-aware contradiction detection** (`.github/copilot-instructions.md`) — updated steps 4–5 so agents search `DECISIONS_ARCHIVE.md` when working on legacy modules or when no match is found in active decisions.
- **Quarterly memory health check** (`docs/adoption-guide.md`) — added step 7 to the maintenance loop: archive if >50 entries, purge unpromoted session memory, verify no stale constraint references.

### Changed

- **Record step update** (`docs/agent-playbook.md`) — Record step now includes a lifecycle maintenance check via the `memory-and-state` skill.

---

## [0.5.0] - 2026-04-08

### Changed

- **Workflow clarity hardening** (`AGENTS.md`, `docs/agent-playbook.md`) — defined the loop as a canonical superset and required explicit path selection after triage so Small path simplification is not interpreted as implicit step skipping.
- **Verifiable first-response requirement** (`docs/agent-playbook.md`, `docs/operating-rules.md`, `.github/copilot-instructions.md`) — added a mandatory compliance block (read set, scale, path decision, checkpoint map) before implementation starts.
- **Small-path minimum output contract** (`docs/operating-rules.md`, `docs/agent-playbook.md`, `skills/demand-triage/SKILL.md`) — codified non-skippable explicit outputs for Small tasks: preamble, contradiction check result, validation reporting, and concise deliverable structure.
- **Feedback loop governance** (`docs/operating-rules.md`, `docs/agent-playbook.md`, `docs/agent-templates.md`) — added task-end mini retrospectives, rolling quality signals, and escalation triggers so process quality is continuously measured and corrected.

---

## [0.4.0] - 2026-04-08

### Added

- **New skill: `demand-triage`** (`skills/demand-triage/SKILL.md`) — introduces scale classification (Small / Medium / Large), hard blockers, reclassification guidance, and conformance self-check.
- **Scale-aware templates** (`docs/agent-templates.md`) — added demand classification template and task completion summary template for consistent reporting.

### Changed

- **Core workflow synchronization** (`AGENTS.md`, `docs/agent-playbook.md`, `.github/copilot-instructions.md`) — aligned loop and step ordering around `Discover → Triage → ... → Summarize`, and synchronized mandatory workflow guidance across docs.
- **Small-task deliverable rule consistency** (`docs/agent-playbook.md`, `skills/demand-triage/SKILL.md`, `docs/agent-templates.md`) — clarified that mandatory deliverable structure remains required for Small tasks, but can be concise; summary is additional, not a replacement.
- **Context compaction guidance** (`docs/operating-rules.md`, `skills/memory-and-state/SKILL.md`) — added compaction protocol and workflow synchronization guardrail to reduce drift and stale instruction risk.
- **Skill quality upgrades** (`skills/application-implementation/SKILL.md`, `skills/backend-change-planning/SKILL.md`, `skills/error-recovery/SKILL.md`, `skills/feature-planning/SKILL.md`, `skills/test-and-fix-loop/SKILL.md`) — added conformance self-checks; expanded testing guidance with scale-aware strategy and test-first recommendations.
- **Decision log update** (`DECISIONS.md`) — recorded the adaptive-workflow decision and corrected context wording to match actual process.

### Metadata

- **Diff vs main**: 13 files changed, 461 insertions, 24 deletions.
- **Changed files**: `.github/copilot-instructions.md`, `AGENTS.md`, `DECISIONS.md`, `docs/agent-playbook.md`, `docs/agent-templates.md`, `docs/operating-rules.md`, `skills/application-implementation/SKILL.md`, `skills/backend-change-planning/SKILL.md`, `skills/demand-triage/SKILL.md` (new), `skills/error-recovery/SKILL.md`, `skills/feature-planning/SKILL.md`, `skills/memory-and-state/SKILL.md`, `skills/test-and-fix-loop/SKILL.md`.

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
[0.5.0]: https://github.com/screenleon/agent-playbook-template/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/screenleon/agent-playbook-template/compare/v0.3.0...v0.4.0
[0.2.0]: https://github.com/screenleon/agent-playbook-template/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/screenleon/agent-playbook-template/releases/tag/v0.1.0
