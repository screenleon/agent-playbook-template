# Changelog

All notable changes to this project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added

- **`skills/alignment-loop/SKILL.md`** — new Conditional skill that runs between
  Triage and feature-planning on Medium/Large tasks. Forces structured
  challenge → response → closure protocol before implementation begins,
  surfacing design gaps and unstated decisions that would otherwise only
  appear as wrong code. Includes autonomous mode escalation behavior and
  respects `decision_log.policy` for where to record Patched decisions.

- **`skills/ubiquitous-language/SKILL.md`** — new Conditional skill for building
  and maintaining `UBIQUITOUS_LANGUAGE.md` as a shared semantic layer.
  Prevents semantic drift across agents and sessions by defining canonical
  domain terms loaded via `memory-and-state` context. Activates at
  `on-project-start` or whenever a new domain term is introduced.

- **`docs/external-practices-notes.md`** — two new sections: (1) APOSD Deep
  Module principle (simple interface, powerful internals) as a design
  quality criterion for agent-callable abstractions; (2) alignment-loop and
  ubiquitous-language as first-party implementations of patterns from
  `mattpocock/skills`.

### Changed

- **`AGENTS.md`** — updated skill count (16 → 18), added `[Align]` node to the
  Loop definition, added Core rules for alignment-loop and ubiquitous-language
  including conditional loading behavior when `UBIQUITOUS_LANGUAGE.md` does
  not yet exist.

- **`docs/agent-playbook.md`** — updated skill count (16 → 18), added
  `alignment-loop` and `ubiquitous-language` to Conditional tier table,
  updated Loop and stateDiagram to include the Align node between Triage
  and Plan for Medium/Large paths.

- **`prompt-budget.yml`** — added `alignment-loop` and `ubiquitous-language`
  to `skills.on_demand` with trigger condition comments.

- **`docs/schemas/context-pack.schema.json`** — schema bumped to 1.1.0 (both
  1.0.0 and 1.1.0 validate) with a new optional `orchestration` block that
  records `budget`, `selection`, `dropped`, and `determinism` metadata for
  budget-aware context orchestration. Adapter-neutral by construction: the
  block describes pack-assembly decisions using canonical repo refs only,
  with no IDE/session state.
- **`scripts/build-context-pack.py`** — zero-dep (stdlib only) deterministic
  context-pack builder. Reads `AGENTS.md`, `rules/global/`, `rules/domain/`,
  `project/project-manifest.md`, `DECISIONS.md`, and `docs/schemas/` to
  assemble a pack conforming to schema 1.1.0. Ranks candidate refs by
  priority, fills within a profile-aware token budget, and emits
  `orchestration.determinism.{input_hash,output_hash}` so identical inputs
  produce byte-identical packs.
- **`evals/tooling/`** — new fixture namespace for tooling output checks.
  `evals/tooling/context-pack-determinism/` verifies the builder is
  byte-deterministic and matches a checked-in golden `expected.json`.
- **`scripts/test-tooling.sh`** — runner for `evals/tooling/` fixtures.
  Exits non-zero on any mismatch so it can gate CI.

## [0.18.0] - 2026-04-22

### Added

- **`docs/schemas/trace.schema.yaml`** — canonical, adapter-neutral schema for
  `.agent-trace/*.trace.yaml`. Formalizes the previously implicit format so any
  runtime (claude-code, copilot, cursor, opencode, windsurf, generic) emits
  traces that downstream tooling can consume. Adds optional `budget`,
  `failure_families`, `runtime`, `eval_id`, and `task_summary` blocks for
  advanced diagnostics without breaking the existing minimal/standard/full
  depths.
- **`scripts/trace-query.py`** — zero-dep Python analytics over
  `.agent-trace/*.trace.yaml`. Flags: `--skill-hit-rate`, `--gate-activations`,
  `--failure-families`, `--budget-usage`, `--role-transitions`, `--isolation`,
  `--summary`, `--format table|json`. Uses a shared parser so adapters that
  cannot load PyYAML still work. Enables the self-evolution protocol
  (previously "on paper") to be triggered by measurable signals.
- **`scripts/trace_query_impl.py`** — shared zero-dep YAML parser module for
  trace/expected-behavior files. Used by `trace-query.py` and `score-eval.py`
  to keep the tooling surface consistent and dependency-free.
- **`scripts/decisions-conflict-check.py`** — zero-dep pre-plan contradiction
  detector. Keyword-overlap with heading weighting + negation/antonym boosting.
  Flags: `--text`, `--file`, `--decisions`, `--top`, `--warn-threshold`,
  `--format table|json`. Emits verdicts `likely_conflict` (exit 1),
  `possible_conflict`, or `no_likely_conflict` (exit 0). Any agent, any
  adapter, can shell out to it before planning.
- **`evals/` framework** — adapter-neutral governance evaluation suite with
  6 seed fixtures: `small-typo-fix`, `medium-add-endpoint`,
  `large-schema-migration`, `trap-scope-expansion`, `trap-decisions-conflict`,
  `trap-destructive-action`. Each fixture pairs a `task.md` prompt with an
  `expected-behavior.yaml` contract. `evals/README.md` and
  `evals/schema/expected-behavior.schema.yaml` document the interface.
- **`scripts/run-evals.sh`** — adapter-neutral eval runner. Does not hardcode
  any runtime; shells out to the user-provided `$AGENT_INVOKE` command with a
  stable three-argument contract (`task.md`, `eval_id`, `trace_output_path`).
  Aggregates per-fixture results and exits non-zero on any failure.
- **`scripts/score-eval.py`** — compares a trace YAML against an
  `expected-behavior.yaml` contract. Checks scale, required/forbidden roles,
  required skills, required gates, file-count bounds, reflection dimensions,
  decisions-made policy, and trap-specific responses. Missing expectations are
  skipped (not failed), so fixtures can declare only what matters.
- **`evals/adapters/manual.sh`** — works with any tool; prints the prompt and
  waits for the user to save the trace by hand. No automation required.
- **`evals/adapters/generic-cli.sh`** — template wrapper for any CLI-based
  agent runtime. Copy, set `AGENT_CMD`, done. Prompt includes a directive
  telling the agent where to write the trace.

### Changed

- **`skills/error-recovery/SKILL.md`** — the "3 attempts then escalate" rule
  is now *same-family*. New **Step 5a: Failure-family check** instructs all
  adapters to run `harness/core/failure-family-detect.sh` (or emulate it) and
  record per-attempt family in the trace's `failure_families[]` block.
  Conformance self-check and auditable indicators updated accordingly.

## [0.17.0] - 2026-04-21

### Added

- **`scripts/validate-prompt-budget.py`** — zero-dependency Python schema validator for `prompt-budget.yml` (and local override examples). Validates `execution_mode`, `budget.profile`, `model_routing` tiers/policy/trigger IDs, role and skill overlap, and `autonomous_mode` safety flags. Supports `--all` to also validate `prompt-budget.local.example.yml`. Now runs in CI via the `validate-prompt-budget` job.
- **`harness/core/failure-family-detect.sh`** — reference implementation for `repeated_failed_fix_loop` failure-family detection. Normalizes line numbers, addresses, and timestamps before comparison; classifies errors into 7 families (test_failure, lint, build_error, exception, schema_error, auth_error, infra_error); returns exit 0 (same family), 1 (different), or 2 (unknown/missing). Adapters call this to decide when to escalate.
- **`scripts/decisions-context.sh`** — compact pre-planning context extractor for `DECISIONS.md`. Flags: `--full-recent N` (full text of N most recent entries), `--headings-only`, `--file PATH`. Enables agents to perform contradiction checks without loading the entire file.
- **`scripts/budget-report.sh`** — token cost estimator (word count × 1.35). Prints per-layer OK/WARN/OVER status table against targets in `prompt-budget.yml`. Flags: `--warn-only`, `--json`. Override via `BUDGET_TOKEN_MULTIPLIER` env var.
- **`docs/adapter-capability-matrix.md`** — comparison table across all 6 adapters (claude-code, copilot, cursor, opencode, windsurf, generic) covering: native hook API, gate enforcement, trace validation, subagent isolation, model routing, CI enforcement, failure-family-detect usability. Includes decision tree for choosing an adapter.
- **`examples/anti-patterns.md`** — 13 concrete anti-patterns (AP-C1–C4 configuration, AP-M1–M2 manifest, AP-W1–W4 workflow, AP-S1–S2 security) with symptom, problem, and correct approach for each.
- **`MIGRATION.md`** — version upgrade guide for adopters. Covers 0.17.x (all new files and required manual steps), 0.15.x→0.16.x (manifest constraint source), 0.14.x→0.15.x (ARCHITECTURE.md/DECISIONS.md), 0.13.x→0.14.x (compaction template). Includes a general upgrade checklist.
- **`rules/global/prompt-injection.md`** — GSEC-PI-001: prompt injection defense rule (OWASP LLM01). Includes detection signals table and a 4-step response protocol (alert → stop → propose safe path → record in trace).
- **`harness/adapters/*/conformance.sh`** (6 files) — per-adapter conformance scripts for claude-code, copilot, cursor, opencode, windsurf, and generic. Each verifies the adapter can read `execution_mode`, `budget.profile`, and `model_routing.enabled` from `prompt-budget.yml`, and checks adapter-specific required files (governance-block.md, harness.mdc, harness.md, harness-rules.md, pre/post-invoke hooks).

### Changed

- **`rules/global/security-baseline.md`** — expanded from 3 rules to 7. Added GSEC-004 (dependency pinning / supply chain, OWASP A06), GSEC-005 (input validation at system boundaries, OWASP A03/A01), GSEC-006 (secure defaults / deny-by-default, OWASP A05), GSEC-007 (security logging, no secrets in logs, OWASP A09).
- **`skills/test-and-fix-loop/SKILL.md`**, **`skills/error-recovery/SKILL.md`**, **`skills/feature-planning/SKILL.md`**, **`skills/demand-triage/SKILL.md`** — added YAML frontmatter with `depends_on` and `commonly_followed_by` fields to make skill dependency chains explicit. Added `## Common misuses` section to each with 4–5 concrete pitfalls and correct approaches.
- **`scripts/agent-review.sh`** — added skill hit rate analytics: parses `skills_loaded:` field from trace files, accumulates per-skill load count and fail-outcome co-occurrence, prints `skill_analytics:` YAML block in report output. Also added a check: `scale>=Medium` traces missing `task_summary` field now produce a `low`-severity finding.
- **`.github/workflows/rule-governance.yml`** — added two new CI jobs: `shellcheck` (runs shellcheck --severity=warning on all `scripts/` and `harness/` shell scripts) and `validate-prompt-budget` (runs `python3 scripts/validate-prompt-budget.py --all`). Expanded `on.push.paths` and `on.pull_request.paths` to cover `skills/**`, `harness/**`, `MIGRATION.md`, `scripts/*.py`, and `prompt-budget.local.example.yml`.
- **`README.md`** — replaced the "30-Second TL;DR" section with structured Day 0 / Day 1 / Day 7 onboarding paths and a checkpoint gate × execution mode matrix showing STOP / Advisory / auto-proceed behavior per gate.

### Fixed

- **`scripts/validate-prompt-budget.py`** — fixed three bugs: (1) `parse_yaml_scalars` now strips inline comments from unquoted scalar values; (2) `_extract_block` now uses indent-level tracking so the `tiers:` block does not bleed into the sibling `policy:` block; (3) `--all` mode no longer fails on `prompt-budget.local.example.yml` for missing `execution_mode`/`budget.profile` (override files legitimately omit those fields).

## [0.16.0] - 2026-04-19

### Added

- **Starter adoption audit** (`scripts/adoption-audit.sh`, `.github/workflows/rule-governance.yml`, `docs/adoption-guide.md`, `README.md`) — added a minimal audit script that catches blank project manifest fields, untouched project-specific constraints, empty decision logs, unchanged template architecture docs, and missing CI review scripts. The template repo runs it in advisory `--template-mode`; adopters can switch to `--strict` after first customization.
- **Starter CI trace review script** (`scripts/agent-review.sh`, `.github/workflows/agent-review.yml`) — replaced the placeholder CI hook with a working shell-based reviewer for `.agent-trace/*.trace.yaml`. The starter rubric treats malformed traces as parse errors, `validation_outcome: fail` as severity-high, multiple reflection failures as severity-medium, and missing Medium/Large decisions as severity-low.
- **Medium task trace example** (`.agent-trace/example-medium-change.trace.yaml`) — added a Medium-scale trace with `decisions_made` entries, multiple roles, and full reflection summary. Complements the existing Small trace example.
- **Global security baseline starter** (`rules/global/security-baseline.md`) — added starter rule file with 3 core-stability security rules in the canonical rule-entry format (no secrets in code, no unvalidated input execution, require auth checks). Fills the gap in the three-layer architecture where `rules/global/` had only a README.
- **Adoption audit: `prompt-budget.yml` validation** (`scripts/adoption-audit.sh`) — audit now checks that `prompt-budget.yml` exists, `execution_mode` is valid, and `budget.profile` is set.
- **Adoption audit: required doc existence** (`scripts/adoption-audit.sh`) — audit now verifies `docs/rules-nano.md`, `docs/rules-quickstart.md`, `docs/operating-rules.md`, and `docs/agent-playbook.md` exist.
- **Doc lint: asset count validation** (`scripts/lint-doc-consistency.sh`) — lint now verifies hardcoded skill and agent counts in `README.md` match the actual filesystem.

### Changed

- **Concise-output guidance tightened** (`docs/operating-rules.md`, `docs/rules-quickstart.md`, `.github/copilot-instructions.md`) — added an explicit rule to default to the shortest output that still preserves assumptions, scope, validation, and blockers.
- **Project-local constraint source clarified** (`project/project-manifest.md`, `docs/operating-rules.md`, `docs/adoption-guide.md`, `README.md`, `skills/repo-exploration/SKILL.md`, `skills/memory-and-state/SKILL.md`, `skills/demand-triage/SKILL.md`, `skills/documentation-architecture/SKILL.md`, `skills/design-to-code/SKILL.md`, `docs/agent-templates.md`) — moved active repo-specific constraints to the manifest as the single source of truth and updated references accordingly.
- **Skill structural consistency** (6 skills) — added missing `## Conformance self-check` sections to `documentation-architecture`, `mcp-validation`, `memory-and-state`, `observability`, `repo-exploration`, `self-reflection`. Added missing `## Use this skill when` sections to `backend-change-planning`, `mcp-validation`, `observability`, `on-project-start`, `prompt-cache-optimization`, `self-reflection`.
- **CI push trigger** (`.github/workflows/rule-governance.yml`) — added `push` trigger on `main` branch so direct merges and hotfixes also run governance checks.
- **Trace extension standardization** (`scripts/agent-review.sh`, `.github/workflows/agent-review.yml`) — standardized on `.trace.yaml` extension; removed fallback `*.yaml` glob that could match non-trace files.
- **ARCHITECTURE.md** — simplified adopter-facing language to avoid triggering audit warnings.

### Fixed

- **`agent-review.sh` decisions exit code bug** (`scripts/agent-review.sh`) — fixed bug where `decisions_has_entries` exit code (1=empty, 2=malformed) was lost inside an if/else, always reading as 1.
- **`lint-doc-consistency.sh` missing file guards** (`scripts/lint-doc-consistency.sh`) — script no longer fails with grep exit code 2 when optional paths (`CHANGELOG.md`, `examples/`) do not exist. All search paths are now guarded with existence checks.
- **`adoption-audit.sh` missing file guards** (`scripts/adoption-audit.sh`) — audit now checks `docs/operating-rules.md` and `ARCHITECTURE.md` exist before grepping them, so missing files are reported through `report_issue` instead of raw shell errors.
- **`lint-doc-consistency.sh` portability and optional-dir handling** (`scripts/lint-doc-consistency.sh`) — README asset-count parsing now uses `awk` instead of `grep -P`, and optional `skills/` / `.claude/agents/` directories are guarded before counting.
- **`agent-review.sh` quoted fail detection** (`scripts/agent-review.sh`) — reflection failure counting now treats both `fail` and `"fail"` scalars as severity-medium signals.
- **`prompt-budget.yml` comment** — profile example reference now correctly lists all four profiles (nano/minimal/standard/full).

## [0.15.0] - 2026-04-16

### Added

All items in this release are inspired by [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — a set of Karpathy-derived behavioral guidelines for reducing common LLM coding mistakes.

- **Quick self-check sentences** (`docs/rules-quickstart.md`, `docs/rules-nano.md`) — added four one-line self-tests (assumption check, simplicity check, surgical check, goal check) that agents apply before emitting any code change. These directly counter the most common LLM pitfalls: silent assumptions, overengineering, orthogonal edits, and vague execution. The nano profile uses a more compact phrasing (~40 tokens less).

- **"How to know it's working" sections** (`skills/application-implementation/SKILL.md`, `skills/test-and-fix-loop/SKILL.md`, `skills/error-recovery/SKILL.md`, `skills/feature-planning/SKILL.md`) — each skill now includes observable success indicators so agents (and users) can verify the skill is being applied effectively, not just loaded. Indicators are specific and measurable (e.g., "diffs contain only requested changes", "fixes are minimal", "escalation reports are actionable").

- **Step → verify pattern** (`skills/test-and-fix-loop/SKILL.md`) — added a structured `[Step] → verify: [check]` template for multi-step tasks, with a weak-vs-strong verification comparison table. Transforms imperative instructions into declarative goals with verification loops, enabling agents to loop independently on strong criteria.

### Changed

- **Template architecture documented** (`ARCHITECTURE.md`) — replaced placeholder content with a concrete module map, repository data flow, key governance interfaces, external dependencies, deployment units, and known technical debt notes for this template repository.
- **Decision-log template cleanup** (`DECISIONS.md`, `DECISIONS_ARCHIVE.md`) — converted the in-file example decision heading to a comment-only template and moved template-framework decisions to `DECISIONS_ARCHIVE.md` so adopters inherit a clean active decision log.
- **Runtime docs made auditable** (`docs/rules-quickstart.md`, `docs/rules-nano.md`, `skills/application-implementation/SKILL.md`, `skills/error-recovery/SKILL.md`, `skills/feature-planning/SKILL.md`, `skills/test-and-fix-loop/SKILL.md`) — converted subjective guidance into evidence-based pass conditions (scope traceability, command execution evidence, testability evidence, risk-field completeness, and escalation evidence).
- **README alignment for architecture state** (`README.md`) — adoption step now clarifies that `ARCHITECTURE.md` contains a reference architecture for this template and must be replaced by adopters.

### Attribution

All additions reference the source: [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (MIT License). The four behavioral principles (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution) were adapted into the existing playbook structure rather than adopted verbatim.

## [0.14.0] - 2026-04-15

### Added

- **Compaction summary template** (`docs/agent-templates.md`) — added a canonical template for mid-session context compaction with explicit handoff framing, resolved-vs-pending question tracking, critical-context preservation, and iterative-update guidance. This makes compaction output reusable across agents while reducing repeated work after long conversations.

### Changed

- **agent-playbook long-task compaction guidance** (`docs/agent-playbook.md`) — the mandatory workflow now points long-running tasks to `docs/agent-templates.md` → Compaction summary template so session compaction is documented alongside task completion summaries.
- **memory-and-state compaction guidance** (`skills/memory-and-state/SKILL.md`) — Tier 2 summaries and the compaction protocol now reference `docs/agent-templates.md` → Compaction summary template as the single source of truth instead of redefining the format inline. Keeps compaction rules aligned while avoiding template drift.
- **prompt-cache-optimization cache safety guidance** (`skills/prompt-cache-optimization/SKILL.md`) — added cache-breaking anti-patterns for mid-task prompt rebuilds, unstable tool subsets, unnecessary memory reloads, and accidental promotion of volatile notes into stable layers.
- **operating-rules context compaction reference** (`docs/operating-rules.md`) — the context compaction rule now points directly to `docs/agent-templates.md` → Compaction summary template so rules, skills, and templates all reference the same canonical format.
- **documentation consistency sweep** (`AGENTS.md`, `README.md`, `.github/copilot-instructions.md`, `prompt-budget.yml`, `docs/example-task-walkthrough.md`, `skills/memory-and-state/SKILL.md`, `docs/agent-templates.md`, `docs/operating-rules.md`) — aligned the `nano` bootstrap order, source-of-truth wording, autonomous-mode defaults, Copilot autonomous configuration guidance, decision-log format, canonical context-anchor usage, and compliance-block references to remove stale or conflicting instructions across docs.
- **autonomous-mode configuration alignment** (`docs/operating-rules.md`, `docs/agent-playbook.md`, `.github/copilot-instructions.md`, `README.md`) — normalized docs around `prompt-budget.yml` → `execution_mode` / `autonomous_mode.*`, clarified which autonomous stops are configurable vs. non-bypassable, and aligned scope-expansion behavior with the canonical checkpoint rules.

## [0.13.0] - 2026-04-14

### Changed

- **prompt-cache-optimization preamble** (`skills/prompt-cache-optimization/SKILL.md`) — inlined the "Why this matters" section into the opening paragraph (~110 tokens saved, no information lost).
- **demand-triage conformance self-check** (`skills/demand-triage/SKILL.md`) — compressed 5-item checkbox list to 3 compact bullets (~60 tokens saved).
- **repo-exploration "Use this skill when"** (`skills/repo-exploration/SKILL.md`) — merged 4 bullets to 2 inline conditions (~30 tokens saved).
- **on-project-start Goal section** (`skills/on-project-start/SKILL.md`) — merged standalone "## Goal" section into opening paragraph (-3 lines, ~40 tokens saved).
- **memory-and-state cache interaction note** (`skills/memory-and-state/SKILL.md`) — removed "Interaction with prompt cache optimization" subsection; content is self-evident from the four-layer loading order in prompt-cache-optimization/SKILL.md (~70 tokens saved).
- **AGENTS.md configuration layering** (`AGENTS.md`) — collapsed numbered list to inline chain; shortened compliance block description (-6 lines, ~60 tokens saved).
- **prompt-budget.yml header comments** (`prompt-budget.yml`) — compressed 16-line HOW TO USE + TEMPLATE DEFAULT comment block to 4 lines (-12 lines, ~60 tokens saved).

### Token impact summary

| File | Lines removed | Est. tokens saved |
|------|--------------|------------------|
| `skills/prompt-cache-optimization/SKILL.md` | −5 | ~110 |
| `skills/demand-triage/SKILL.md` | −4 | ~60 |
| `skills/repo-exploration/SKILL.md` | −2 | ~30 |
| `skills/on-project-start/SKILL.md` | −3 | ~40 |
| `skills/memory-and-state/SKILL.md` | −6 | ~70 |
| `AGENTS.md` | −6 | ~60 |
| `prompt-budget.yml` | −12 | ~60 |
| **Total** | **−38** | **~430** |

---

## [0.12.0] - 2026-04-14

### Added

- **Nano budget profile** (`docs/rules-nano.md`, `docs/prompt-budget-examples.md`) — new `nano` profile targeting < 3,000 total execution tokens. Loads zero skills; agents use native tool capabilities only. Layer 1 is a single self-contained ~630-token file (`docs/rules-nano.md`) covering constitutional principles, always-dangerous ops, 5-step workflow, error recovery, and escalation triggers. Suitable for single-file Small tasks only — agent escalates immediately if task is multi-file or higher risk. Estimated total execution: ~2,000–2,500 tokens (AGENTS.md + rules-nano.md + DECISIONS.md + task files).
- **Budget profile examples extracted** (`docs/prompt-budget-examples.md`) — moved the profile example blocks out of `prompt-budget.yml` into a standalone reference file. `prompt-budget.yml` now references the doc with a 3-line comment. Saves ~1,500 tokens from every bootstrap read (prompt-budget.yml shrinks from ~3,825 to ~2,325 tokens).
- **Output style at minimal profile** (`docs/rules-quickstart.md`) — explicit brevity contract: no compliance block for Small tasks at `semi-auto`, no context anchor, summary ≤ 3 sentences, errors include file+line only. Reduces completion tokens per task.

### Changed

- **demand-triage Medium/Large workflow sections** (`skills/demand-triage/SKILL.md`) — replaced two verbose workflow sections (~350 tokens) with a single compact block (~60 tokens). At `minimal` profile: output scale label and escalate. At `standard`/`full`: follow `docs/agent-playbook.md` → Workflow chains. Net saving: ~290 tokens per request across all profiles.
- **AGENTS.md skill enumeration** (`AGENTS.md`) — replaced the 16-skill inline list (~150 tokens) with a reference link. Net saving: ~150 tokens per request.
- **repo-exploration ARCHITECTURE.md skip** (`skills/repo-exploration/SKILL.md`) — at `minimal` profile for single-file Small tasks, skip `ARCHITECTURE.md` unless it has substantive non-template content. Mirrors the same rule added to `docs/rules-quickstart.md`. Saves ~875 tokens per qualifying task.

### Token impact summary (minimal Small task)

| Component | Before | After | Delta |
|-----------|--------|-------|-------|
| `prompt-budget.yml` (bootstrap) | ~3,825 | ~2,325 | **−1,500** |
| `demand-triage` (L2) | ~1,964 | ~1,674 | −290 |
| `AGENTS.md` (L1) | ~980 | ~830 | −150 |
| `ARCHITECTURE.md` (L3, skipped) | ~875 | 0 | −875 |
| **Total** | **~10,011** | **~6,480** | **−3,531 (−35%)** |

---

## [0.11.0] - 2026-04-14

### Added

#### Workflow & Orchestration

- **Step phase classification** (`docs/agent-playbook.md`) — classifies 16 mandatory steps into PRE (auto-inject context), CORE (agent work), and POST (auto-finalize) execution phases. Inspired by CowAgent PRE/POST\_PROCESS pattern. Informational only — no new steps added. Optional `post_steps_skip` configuration hook in `prompt-budget.yml`.
- **Checkpoint gate three-outcome model** (`docs/operating-rules.md`) — formalizes checkpoint results as STOP / ADVISORY / PASS. ADVISORY replaces the informal "advisory notice only" wording; gates that do not activate produce PASS (no output). Existing checkpoint activation matrix updated with new terminology. Advisory template added to `docs/agent-templates.md`.

#### Skills (new)

- **Skill creator meta-skill** (`skills/skill-creator/SKILL.md`) — on-demand skill for generating new SKILL.md files from user-described capabilities. Includes boundary definition, skeleton generation, integration checklist, and validation. Respects self-evolution guardrails (human approval required). Skill count: 15 → 16.

#### Skills (enhanced)

- **Relevance scoring formula** (`skills/memory-and-state/SKILL.md`) — optional time-decay scoring (`2^(-age/half_life)`) for ranking memory entries during selective retrieval. Supports `evergreen` entries that bypass decay. Does not affect archive rules. Configurable `relevance_half_life_days` in `prompt-budget.yml`.
- **Retrieval degradation chain** (`skills/memory-and-state/SKILL.md`) — explicit four-level fallback path: RAG → keyword+recency → title scan → full read. Consolidates existing scattered fallback logic into a deterministic chain with mandatory logging.

#### Configuration

- **Configuration file layering** (`docs/layered-configuration.md`) — optional override chain for `prompt-budget.yml`: base file ← `prompt-budget.local.yml` ← `AGENT_BUDGET_PROFILE` env var. Includes sensitive value masking convention (keys containing `key`, `secret`, `token`, `password`, `credential` are masked as `***MASKED***` in all agent output).
- **Profile-aware Layer 1 loading** (`docs/rules-quickstart.md`, `skills/prompt-cache-optimization/SKILL.md`) — agents now select Layer 1 content based on `budget.profile`: `minimal` loads only `docs/rules-quickstart.md` (~1,200 tokens), `standard` defers to full docs as needed, `full` loads everything immediately. Reduces minimal-profile Layer 1 from ~18,350 tokens to ~1,200 tokens (93% reduction). Enhanced `rules-quickstart.md` with constitutional principles, checkpoint outcomes, and minimal-profile role definitions so it is self-sufficient as a standalone Layer 1.

### Changed

- **Checkpoint activation matrix** (`docs/operating-rules.md`) — terminology updated from informal "Always/Skip/Advisory notice/Recommended" to formal STOP/ADVISORY/PASS outcomes.
- **Skill count** (`AGENTS.md`, `docs/agent-playbook.md`, `README.md`) — updated from 15 to 16 skills.
- **Self-evolution protocol** (`docs/agent-playbook.md`) — added link to `skill-creator` for proposals that identify new skill needs.
- **`.gitignore`** — added `prompt-budget.local.yml` to support local override chain.
- **Loading instructions** (`AGENTS.md`, `.github/copilot-instructions.md`) — profile-aware branching: at `minimal`, agents use `docs/rules-quickstart.md` as complete Layer 1 without loading full source-of-truth docs. Execution mode references updated to include all three values (`supervised`, `semi-auto`, `autonomous`).

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
- **Budget profiles** (`docs/agent-playbook.md`, `prompt-budget.yml`, `skills/prompt-cache-optimization/SKILL.md`) — named budget profiles for token-budget-aware skill/role loading. `minimal` loads only 2 skills (~3K-4K tokens) for users with tight token limits; `standard` loads all 5 Always-tier skills; `full` enables all applicable skills and roles. Profile selection via `budget.profile` in `prompt-budget.yml` with explicit override support. Later releases added `nano` for ultra-small single-file tasks.
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
  - Non-bypassable rules: DECISIONS.md contradictions always remain hard stops; destructive actions (gate 2), stuck escalation (gate 4), and severity-high risk-reviewer findings remain hard stops by default and may be relaxed only through the documented autonomous-mode flags
  - Mandatory audit log format — every auto-proceeded gate produces a `DECISIONS.md` entry with `Execution mode: Autonomous` field
  - Critic behavior in autonomous mode: critique embedded in handoff artifact; implementers must address each point
  - Risk-reviewer behavior: runs whenever the routed workflow includes it, including required post-implementation review; severity-high findings stop the agent by default in autonomous mode unless `halt_on_high_severity_risk: false` is explicitly configured
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
