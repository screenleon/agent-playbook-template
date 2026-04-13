# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.10.0] - 2026-04-13

### Added

#### Rules & Safety
- **Rule stability classification** (`docs/operating-rules.md`, `docs/layered-configuration.md`) — orthogonal stability dimension (`core` / `behavior` / `experimental`) layered on top of existing scope layers (Global / Domain / Project). Includes change protocol per stability level and governance matrix.
- **Stability field in rule schema** (`rules/domain/README.md`, `rules/domain/backend-api.md`, `rules/domain/frontend-components.md`, `rules/domain/cloud-infra.md`) — every rule entry now requires `- Stability:` field. All starter examples updated.
- **Stability lint validation** (`scripts/lint-layered-rules.sh`) — linter now parses and validates the `Stability` field; rejects rules with missing or invalid values.
- **Constitutional principles** (`docs/operating-rules.md`) — five non-bypassable safety invariants (secret protection, unvalidated input execution, production data backup, auth bypass, security test suppression) that hold regardless of trust level or `dangerouslySkipAllCheckpoints` setting.
- **Workspace boundary masking** (`docs/operating-rules.md`, `project/project-manifest.md`) — path-based domain rule activation/masking using glob patterns. Global rules are never masked. Backward-compatible.
- **Dynamic spawning guardrails** (`docs/operating-rules.md`) — safety guardrails for runtime sub-agent spawning: max depth = 3, no self-delegation, mandatory handoff schema, idle-timeout reclaim, trust-level interaction.
- **CI-driven risk review rules** (`docs/operating-rules.md`) — read-only risk-reviewer mode for CI pipelines with severity-high blocking and no trust-level bypass.
- **Self-evolution guardrails** (`docs/operating-rules.md`) — evolution proposals always require human approval; constitutional principles are immutable via evolution; core stability rules require risk-reviewer; max 3 proposals per cycle.

#### Skills (new)
- **Self-reflection skill** (`skills/self-reflection/SKILL.md`) — intra-role critique-and-revise cycle using a 5-dimension rubric (correctness, consistency, adherence, completeness, isolation). Scale-adaptive: Small uses 2/5 dimensions; Medium/Large use all 5.
- **Observability skill** (`skills/observability/SKILL.md`) — trace record emission at task end. Three depth levels: minimal (Small, inline), standard (Medium), full (Large, per-role). Includes `isolation_status` field and CI integration protocol with exit-code contract and review summary format.
- **MCP dynamic validation skill** (`skills/mcp-validation/SKILL.md`) — pre-flight MCP tool availability checks, fallback strategy, periodic revalidation, and agent-deference notice. Short-circuits when no MCP tools are declared.

#### Skills (enhanced)
- **Triage-driven selective memory retrieval** (`skills/memory-and-state/SKILL.md`) — optional procedure activated when memory entries exceed 30 items or 20 KB.
- **RAG-augmented retrieval** (`skills/memory-and-state/SKILL.md`) — expanded Tier 3 long-term memory with full RAG guidance: indexing targets, refresh triggers, query strategy (top-K), token budget impact, and fallback to file-based retrieval. Entirely optional.

#### Workflow & Orchestration
- **Graph workflow reference** (`docs/agent-playbook.md`) — Mermaid stateDiagram-v2 showing the full agent workflow as a state graph with conditional transitions.
- **Skill activation tiers** (`docs/agent-playbook.md`) — classifies all 15 skills into Always (5 mandatory), Conditional (7 trigger-based), and On-demand (3 opt-in) tiers. Defines the minimum required skill set.
- **Budget profiles** (`docs/agent-playbook.md`, `prompt-budget.yml`, `skills/prompt-cache-optimization/SKILL.md`) — three named budget profiles (`minimal`, `standard`, `full`) for token-budget-aware skill/role loading. `minimal` loads only 2 skills (~3K-4K tokens) for users with tight token limits; `standard` loads all 5 Always-tier skills; `full` enables all applicable skills and roles. Profile selection via `budget.profile` in `prompt-budget.yml` with explicit override support.
- **Dynamic orchestration** (`docs/agent-playbook.md`) — coordinator roles can dynamically spawn sub-roles at runtime with plan-of-record tracking, max depth = 3, idle reclaim.
- **Self-evolution protocol** (`docs/agent-playbook.md`) — feedback-driven rule/skill improvement proposals with evidence requirements, risk-routing, and mandatory human approval.
- **Context isolation verification** (`docs/agent-playbook.md`) — detection and recording of context isolation violations via self-reflection rubric and trace `isolation_status` field.

#### Schemas & Templates
- **Structured handoff schema** (`docs/schemas/handoff-artifact.schema.yaml`) — machine-readable YAML schema with `state` fields and optional `orchestration` block (`parent_role`, `spawn_depth`, `plan_of_record_ref`).
- **Plan of record template** (`docs/agent-templates.md`) — table for coordinators to track expected vs. actual sub-agent routing.
- **Evolution proposal template** (`docs/agent-templates.md`) — standard format for self-evolution proposals with target, evidence, impact, and risk fields.
- **MCP tool declarations** (`project/project-manifest.md`) — standard location for declaring MCP tools with server endpoints and fallback builtins.

#### CI/CD
- **CI agent review workflow** (`.github/workflows/agent-review.yml`) — GitHub Actions skeleton that collects `.agent-trace/` files and runs a project-specific review script.
- **CI agentic review adoption guide** (`docs/adoption-guide.md`) — step-by-step setup for enabling automated trace-based risk review in CI.

### Changed

- **Safety rails** (`docs/operating-rules.md`) — intro text updated to reference constitutional principles; the "secrets" rule promoted to constitutional principle.
- **Skill count** (`AGENTS.md`, `docs/agent-playbook.md`, `README.md`) — updated from 12 to 15 skills across all references.
- **Mandatory workflow steps** (`docs/agent-playbook.md`) — added steps 12 (Self-reflect) and 14 (Trace); renumbered subsequent steps. Added clarifying note that the 11-stage loop is a conceptual overview expanding into 16 detailed steps.
- **Codebase discovery** (`docs/operating-rules.md`) — added steps 6 (workspace boundaries) and 7 (RAG when configured).
- **Escalation rule** (`docs/operating-rules.md`) — now also applies to context isolation violations (3+ in rolling window).
- **Adoption guide** (`docs/adoption-guide.md`) — added `mcp-validation` to removable skills list; added CI agentic review setup guide; replaced Step 4 with budget-profile-aware guidance.
- **Prompt cache optimization** (`skills/prompt-cache-optimization/SKILL.md`) — added budget profile loading behavior table and `minimal` profile agent instructions; updated how-agents-use-prompt-budget.yml procedure.
- **Project manifest** (`project/project-manifest.md`) — added `Workspace boundaries` and `MCP tool declarations` sections.
- **Handoff artifact template** (`docs/agent-templates.md`) — added reference to structured YAML schema variant.

### Fixed

- **README.md skill count** — corrected stale count from 12 to 15 matching actual `skills/` directory.
- **Broken skill path** (`.github/copilot-instructions.md`) — fixed `on_project_start` → `on-project-start` (underscore → hyphen) matching actual directory name.
- **Execution mode / trust level alignment** (`prompt-budget.yml`) — added `semi-auto` as a valid `execution_mode` option, matching the three trust levels defined in `docs/operating-rules.md`. Default changed from `supervised` to `semi-auto` to match operating-rules.md default.
- **Always-load skill list** (`prompt-budget.yml`) — default `always_load` now includes all 5 Always-tier skills (added `test-and-fix-loop`, `error-recovery`, `memory-and-state`) to match `docs/agent-playbook.md` → Skill activation tiers.
- **Terminology inconsistency** (`docs/agent-templates.md`) — changed "Risk level" to "Severity" in evolution proposal template for consistency with all other docs.
- **Example workflow clarity** (`examples/high-security-mode.md`, `examples/mvp-rapid-mode.md`, `examples/legacy-maintenance.md`) — replaced informal/abbreviated role names with canonical role names; separated skill references from role chains for clarity.

---

## [0.9.0] - 2026-04-13

### Added

- **Layered configuration scaffolding** (`rules/global/README.md`, `rules/domain/README.md`, `project/project-manifest.md`) — introduced three-level constraint structure (Global Rules, Domain Rules, Project Context) with explicit repository templates.
- **Initialization protocol skill** (`skills/on-project-start/SKILL.md`) — first-entry workflow for environment scanning and dynamic boundary-questioning before implementation.
- **Example gallery profiles** (`examples/high-security-mode.md`, `examples/mvp-rapid-mode.md`, `examples/legacy-maintenance.md`) — ready-to-adapt constraint profiles for common operating modes.
- **Rules quickstart** (`docs/rules-quickstart.md`) — compact, first-pass rule-loading document for agents to reduce cognitive and token overhead.
- **Rule optimization roadmap** (`docs/rule-optimization-plan.md`) — phased plan for simplification, template expansion, and CI-based rule governance.
- **Domain rule templates** (`rules/domain/backend-api.md`, `rules/domain/frontend-components.md`, `rules/domain/cloud-infra.md`) — reusable rule skeletons with consistent rule schema.
- **Rule governance automation** (`scripts/lint-layered-rules.sh`, `.github/workflows/rule-governance.yml`) — lightweight layered-rule linting in CI for structure and override-format checks.
- **PR checklist for rule changes** (`.github/pull_request_template.md`) — explicit review checklist when layered rules are modified.
- **Autonomous execution mode** — opt-in mode (`execution_mode: autonomous` in `prompt-budget.yml`) that replaces human checkpoint wait states with auto-proceed + `DECISIONS.md` logging. Full specification in `docs/operating-rules.md` → Autonomous execution mode.
  - Checkpoint gate substitution table (gates 1–6 in supervised vs. autonomous)
  - Non-bypassable rules: destructive actions (gate 2), stuck escalation (gate 4), DECISIONS.md contradictions, and severity-high risk-reviewer findings always remain hard stops
  - Mandatory audit log format — every auto-proceeded gate produces a `DECISIONS.md` entry with `Execution mode: Autonomous` field
  - Critic behavior in autonomous mode: critique embedded in handoff artifact; implementers must address each point
  - Risk-reviewer behavior: always runs after implementation; severity-high findings stop the agent even in autonomous mode
  - "Autonomous mode is not skip planning" — the full workflow structure is preserved; only human wait states are removed
- **`autonomous_mode` block in `prompt-budget.yml`** — six configurable flags: `auto_proceed_on_plan`, `auto_proceed_on_scope_expansion`, `halt_on_destructive_actions`, `halt_on_stuck_escalation`, `skip_critic_role`, `halt_on_high_severity_risk`. Defaults keep all hard stops active.
- **Autonomous mode adoption guide** (`docs/adoption-guide.md`) — step-by-step setup (4 steps), risk tradeoff table, "when not to use" list. Placed in its own top-level section before the tool adapter reference.
- **Autonomous workflow variants table** (`docs/agent-playbook.md`) — maps each supervised workflow to its autonomous equivalent; lists retained hard stops.

### Changed

- **TDAI requirement** (`docs/operating-rules.md`, `docs/agent-playbook.md`, `.github/copilot-instructions.md`) — behavior-changing work now requires test case definition before implementation.
- **ADR automatic update rule** (`docs/operating-rules.md`, `docs/agent-playbook.md`, `.github/copilot-instructions.md`) — architecture-changing work must update ADRs (or fallback decision record) in the same task.
- **Conflict resolution principle** (`docs/operating-rules.md`) — added explicit precedence: user instruction -> existing repo practice -> project context -> domain rules -> global rules.
- **Layered configuration documentation** (`README.md`, `AGENTS.md`, `docs/adoption-guide.md`, `docs/agent-playbook.md`) — synchronized guidance and adoption steps for split rule layers.
- **Layered configuration governance hardening** (`docs/operating-rules.md`, `docs/layered-configuration.md`) — added placement rubric, deterministic conflict resolution algorithm, and layer hygiene guardrails to reduce rule drift and shadow conflicts.
- **Project override tracking format** (`project/project-manifest.md`) — added standardized `Overrides: <base-rule-id> -> <project-rule-id>` annotation and override registry table.
- **Domain layer guide** (`rules/domain/README.md`) — expanded with starter templates and recommended rule-entry schema.
- **Layered-rule linter integrity checks** (`scripts/lint-layered-rules.sh`, `rules/domain/*.md`) — added Rule ID uniqueness validation and superseded-replacement integrity checks via `Superseded by` field.
- `AGENTS.md` — added one-line reference to `prompt-budget.yml` execution mode and adoption guide link.
- `.github/copilot-instructions.md` — added instruction to check `prompt-budget.yml` for `execution_mode` before acting on checkpoint gates.

## [0.8.0] - 2026-04-11

### Added

- **Agent-deference principle** (`docs/operating-rules.md`, `.github/copilot-instructions.md`) — the template now explicitly defers to agent-native capabilities (built-in safety rails, tool routing, output formatting) and only adds rules the agent tool does not provide. Items handled natively are marked `[AGENT-NATIVE]` for adoption-time trimming.
- **Trust level mechanism** (`docs/operating-rules.md`) — three tiers (`supervised`, `semi-auto` default, `autonomous`) plus an opt-in `dangerouslySkipAllCheckpoints: true` flag for fully unattended execution. Checkpoint activation matrix is 6 gates × 4 columns. Always-safe operations never require approval. Always-dangerous operations require approval by default even at `autonomous`; the bypass flag overrides this when the user explicitly accepts the risk.
- **Always-safe / always-dangerous operation lists** (`docs/operating-rules.md`) — absolute categorization: always-safe operations (read, test, lint, branch, diff) need no approval; always-dangerous operations (delete, drop, force-push, publish) require approval by default even at `autonomous`, overridable only with `dangerouslySkipAllCheckpoints: true`.
- **`ARCHITECTURE.md` template skeleton** — adopter-ready blank template with sections for module map, data flow, key interfaces, external service dependencies, deployment units, and known technical debt.
- **`DECISIONS_ARCHIVE.md`** — created with template development history (decisions from 0.1.0–0.7.0). Adopters now inherit a clean `DECISIONS.md` and can find template design rationale in the archive.
- **`docs/example-task-walkthrough.md`** — end-to-end example showing a complete Medium task (add `last_login` field) from codebase discovery through mini retrospective.
- **`prompt-budget.yml`** — reference configuration file with full schema, inline comments, and commented examples for smaller project configurations.
- **`.github/workflows/markdown-lint.yml`** — CI workflow that runs `markdownlint-cli2` on all Markdown files on push and pull request.
- **`.markdownlint.yml`** — markdownlint configuration with explicit rule documentation. Enables MD040 (fenced code block language) and disables rules with intentional exceptions (MD013, MD024, MD029, MD032, MD033, MD034, MD041, MD060).
- **Tool adapter reference** (`docs/adoption-guide.md`) — new section covering Claude Code, GitHub Copilot, Cursor, Windsurf, custom OpenAI API, and Codex CLI setups.

### Changed

- **Human checkpoint gates** (`docs/operating-rules.md`) — rewritten with a 4-column activation matrix across supervised / semi-auto / autonomous / bypass. Always-dangerous operations are now "require approval by default" instead of "always require approval" — overridable with `dangerouslySkipAllCheckpoints`.
- **Validation loop** (`docs/operating-rules.md`, `.github/copilot-instructions.md`) — explicitly autonomous: test → lint → auto-fix → repeat runs without human approval. Escalation to human after 3 consecutive failures.
- **Context isolation** (`docs/operating-rules.md`, `docs/agent-playbook.md`) — Medium tasks at `semi-auto`/`autonomous` may share planner + implementer context instead of requiring strict role isolation.
- **Compliance block** (`docs/operating-rules.md`, `docs/agent-playbook.md`, `.github/copilot-instructions.md`) — now trust-level-aware: required at `supervised`; optional for Small tasks at `semi-auto`/`autonomous`.
- **Small-task output contract** (`docs/operating-rules.md`, `.github/copilot-instructions.md`) — at `semi-auto`/`autonomous`, a brief summary suffices instead of the full structured output.
- **Demand triage workflow adaptation** (`skills/demand-triage/SKILL.md`) — Small task simplifications are now trust-level-qualified (compliance block, deliverable structure). Medium tasks gain context isolation relaxation note. Large task mid-implementation checkpoint respects `autonomous` trust level.
- **Critic review gate** (`docs/agent-playbook.md`, `.github/copilot-instructions.md`) — at `autonomous` trust level, critic review is only mandatory for Large tasks.
- **`DECISIONS.md` cleanup** — moved all template development decisions (2026-04-07 through 2026-04-10) to `DECISIONS_ARCHIVE.md`. Adopters fork with a clean decision log.
- **`skills/design-to-code/SKILL.md` strengthened** — added pre-implementation checklist, scale adaptation table, expanded anti-patterns, and conformance self-check with 10 items.
- **`README.md` updated** — added `ARCHITECTURE.md` and `prompt-budget.yml` to the asset inventory; added `docs/example-task-walkthrough.md` to optional files; updated adoption path to 11 steps.
- **Fenced code block language fixes** — added language specifiers to all unlabeled fenced code blocks across 10 files. Zero markdownlint errors.
- **Hard tabs replaced** (`README.md`) — replaced tab-indented mermaid diagram with spaces.

---

## [0.7.0] - 2026-04-10

### Added

- **Prompt budget trimming guide** (`docs/adoption-guide.md`) — five-step guide for adopting projects to self-trim: remove unused roles, remove unused skills, simplify format templates, configure Layer 2 loading strategy, and set up `prompt-budget.yml`. Includes per-action token savings estimates.
- **`prompt-budget.yml` configuration** (`skills/prompt-cache-optimization/SKILL.md`) — reference schema and agent usage rules for declaring enabled/disabled roles and skills, token budget targets per layer, and trimming thresholds. Agents read this file to respect the declared budget.
- **Format templates section** (`docs/agent-templates.md`) — canonical checkpoint, handoff artifact, context anchor, and deliverable templates moved from `docs/operating-rules.md`.
- **New skill: `prompt-cache-optimization`** (`skills/prompt-cache-optimization/SKILL.md`) — four-layer instruction loading order (static rules → stable skills → project state → volatile context) to maximize prompt cache hit rates across all LLM providers. Includes canonical skill sets per task type, file size guidelines, provider-specific notes (Anthropic, OpenAI, Google, vLLM/SGLang), tool-specific adaptation patterns, and conformance self-check.
- **Tool definition stability** (`skills/prompt-cache-optimization/SKILL.md`) — new section covering deterministic tool ordering, task-type tool subsets, stable schemas, and the tool registry pattern for custom API callers.
- **Conversation memory tiering** (`skills/memory-and-state/SKILL.md`) — three-tier model: short-term (3–5 raw turns), mid-term (compressed summaries), long-term (persistent retrieval with optional RAG). Includes token budget guidelines (~8,500 tokens total).
- **Cache-aware loading step** (`docs/agent-playbook.md`) — added step 7 to mandatory workflow steps referencing the prompt cache skill.
- **Loading order hint** (`.github/copilot-instructions.md`) — added instruction for Copilot agents to follow the four-layer loading order.

### Changed

- **Format template extraction** (`docs/operating-rules.md`) — replaced four verbose format blocks (checkpoint, handoff artifact, context anchor, deliverable structure) with one-line descriptions referencing `docs/agent-templates.md`. Saves ~500 tokens from Layer 1.
- **Common preamble replaced** (`docs/agent-templates.md`) — replaced ~400-token preamble with compact note referencing `docs/operating-rules.md` to eliminate duplication.
- **Demand classification condensed** (`docs/agent-templates.md`) — replaced inline criteria duplication with reference to `skills/demand-triage/SKILL.md`.
- **Cross-file deduplication** — collapsed duplicate definitions of three-layer architecture (`AGENTS.md`), instruction loading order (`docs/operating-rules.md`), compliance block and checkpoint gates (`docs/agent-playbook.md`), and mandatory workflow steps (`.github/copilot-instructions.md`). Each concept now has one source of truth; other files use brief references + links. Estimated savings: ~4,050 tokens per request.
- **Instruction loading order** (`docs/operating-rules.md`) — condensed to a 3-line summary referencing `skills/prompt-cache-optimization/SKILL.md` as the single source.
- **Three-layer architecture** (`AGENTS.md`) — replaced full definition with a compact index referencing `docs/agent-playbook.md`.
- **Compliance block and checkpoint gates** (`docs/agent-playbook.md`) — replaced inline definitions with references to `docs/operating-rules.md`.
- **Mandatory workflow** (`.github/copilot-instructions.md`) — streamlined from 13 steps to 11, aligned with canonical loop.
- **Skill count** (`README.md`) — updated from 10 to 11.
- **Stale reference fix** (`skills/memory-and-state/SKILL.md`) — context anchor protocol now references `docs/agent-templates.md` (where the template was moved) instead of `docs/operating-rules.md`.
- **Conformance self-check precision** (`skills/prompt-cache-optimization/SKILL.md`) — 8 KB guideline now scoped to always-loaded files; on-demand skills may exceed with justification.
- **Agent preamble note** (`docs/agent-templates.md`) — rephrased auto-load assumption to conditional instruction for cross-tool accuracy.
- **Template consistency warning** (`docs/adoption-guide.md`) — Step 3 now warns adopters to update `docs/operating-rules.md` when simplifying templates.
- **Memory-and-state content optimization** (`skills/memory-and-state/SKILL.md`) — condensed categorized memory (3 subsections → 1 table), simplified contradiction detection and archive format blocks. 14,748 → 13,237 bytes (−10%).

---

## [0.6.0] - 2026-04-09

### Added

- **Memory lifecycle management** (`skills/memory-and-state/SKILL.md`) — added decision archive rules (when/how to move stale entries to `DECISIONS_ARCHIVE.md`), selective read strategy (tiered reading table for decisions, architecture memory, session memory), session memory hygiene (promotion rule, cleanup cadence), and memory health indicators (thresholds and actions).
- **Decision archive lifecycle** (`docs/operating-rules.md`) — added archive lifecycle subsection under decision log guidance; expanded mandatory read-before-write to include archive search for legacy module tasks.
- **Archive-aware contradiction detection** (`.github/copilot-instructions.md`) — updated steps 4–5 so agents search `DECISIONS_ARCHIVE.md` when working on legacy modules or when no match is found in active decisions.
- **Periodic memory health check** (`docs/adoption-guide.md`) — added step 7 to the maintenance loop for threshold-triggered memory hygiene, with periodic review as a low-volume backstop.

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
