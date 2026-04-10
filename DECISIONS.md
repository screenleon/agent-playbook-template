# Decision Log

This file records architectural and behavioral decisions that affect future work.
Agents must read this file before planning or implementation tasks.
See `skills/memory-and-state/SKILL.md` for when to read and write.

<!-- Append new decisions below using the format shown. -->
<!-- Do not remove or silently contradict existing entries. -->
<!-- To reverse a decision, add a new entry that explicitly references and supersedes the old one. -->

## YYYY-MM-DD: [Example] Template decision format

- **Context**: Why this decision was needed
- **Decision**: What was decided
- **Alternatives considered**: What was rejected and why
- **Constraints introduced**: What future work must respect

---

<!-- Add real decisions below this line -->

## 2026-04-09: Memory lifecycle management for persistent memory files

- **Context**: Persistent memory files (especially `DECISIONS.md`) grow unboundedly over time. A real-world instance reached ~20,000 characters, consuming significant context tokens and slowing agent discovery. No archival, pruning, or selective-read mechanism existed.
- **Decision**: Introduced a memory lifecycle management system with four mechanisms: (1) decision archive rules — when entry count exceeds 50 or file size exceeds 30 KB, entries whose constraints are no longer enforced move to `DECISIONS_ARCHIVE.md`; (2) selective read strategy — tiered reading (always read active decisions, search archive only for legacy tasks); (3) session memory hygiene — unpromoted session notes are deleted at session end; (4) memory health indicators — thresholds trigger maintenance actions on demand, with quarterly review as a backstop for low-volume projects.
- **Alternatives considered**: Date-based auto-archive (e.g., >90 days) — rejected because age alone does not indicate irrelevance; high-volume projects can exceed thresholds within days, making fixed time windows inadequate. Multi-file topic-based split — rejected because it fragments the decision log and increases discovery cost.
- **Constraints introduced**: Archive operations require safety checks (search for references before moving); archived decisions retain full content (no lossy compression); agents must search archive before concluding no prior decision exists for legacy module work; memory health checks are triggered by threshold indicators, with quarterly review as a low-volume backstop.

## 2026-04-08: Feedback loop governance for process stability and quality

- **Context**: Workflow rules were strengthened, but sustained quality requires a closed loop that continuously captures friction, measures adherence, and triggers wording updates when recurring misses appear.
- **Decision**: Introduced a formal feedback loop requirement with task-end mini retrospectives, rolling quality signals, and a recurrence escalation rule (3 repeated misses triggers source-of-truth update + synchronization + changelog entry).
- **Alternatives considered**: Keep feedback collection informal in ad-hoc comments only. Rejected because informal feedback is hard to aggregate, easy to forget, and does not reliably trigger policy updates.
- **Constraints introduced**: Completed tasks must include feedback mini retrospectives; teams should review quality signals every 10 tasks or weekly; recurring process failures must be corrected through synchronized documentation updates.

## 2026-04-08: Explicit workflow declaration and Small-path output hardening

- **Context**: Recent feedback identified three recurring failure modes: (1) the canonical loop looked universally mandatory while Small path text appeared to permit implicit shortcutting, (2) users could not verify whether required discovery/triage steps were performed, and (3) Small-task minimum output expectations were not consistently enforced across source-of-truth and tool-specific files.
- **Decision**: Hardened workflow guidance across canonical and tool-specific docs by introducing a mandatory first-response compliance block, defining the loop as a canonical superset with explicit post-triage path selection, and codifying a non-skippable Small-task minimum output contract.
- **Alternatives considered**: Keep existing wording and rely on reviewer enforcement only. Rejected because non-explicit requirements are difficult to audit and are frequently interpreted as optional under time pressure.
- **Constraints introduced**: Implementation must not begin without a visible compliance block; Small-path usage must remain explicit and verifiable; workflow-related changes must synchronize `AGENTS.md`, `docs/agent-playbook.md`, `docs/operating-rules.md`, `.github/copilot-instructions.md`, `skills/demand-triage/SKILL.md`, and `CHANGELOG.md`.

## 2026-04-07: Adaptive workflow with demand triage, context compaction, and skill quality enhancements

- **Context**: The playbook applied the same full pre-change workflow of discovery, planning, critique, approval, implementation, the test/lint/fix/repeat validation loop, and decision recording to all tasks regardless of scale. Small tasks (typo fixes, config changes, single-line bug fixes) consumed excessive tokens and time by going through planning agents, critics, risk-reviewers, full deliverable structures, and context anchors. Additionally, long tasks suffered from context bloat with no compaction mechanism, and skills lacked self-verification checklists.
- **Decision**: Introduced four changes:
  1. **Demand triage** (`skills/demand-triage/SKILL.md`) — classify tasks as Small/Medium/Large after codebase discovery, using observable criteria (file count, contract/schema impact, auth/security involvement). Small tasks get conditional simplifications within the existing single workflow (no parallel workflow fork). Triage happens after discovery, not before.
  2. **Context compaction** (`skills/memory-and-state/SKILL.md` + `docs/operating-rules.md`) — mandatory progress summaries after each phase of multi-phase tasks. Continue from summary, not full history. Includes post-task completion summary template.
  3. **Categorized memory** (`skills/memory-and-state/SKILL.md`) — project-level, component-level, and change-pattern memory tiers. Small tasks query change-pattern memory before implementing.
  4. **Skill quality** — added conformance self-check sections to `feature-planning`, `backend-change-planning`, `test-and-fix-loop`, `application-implementation`, and `error-recovery` skills. Added TDD guidance and scale-adapted testing strategy. Expanded anti-patterns with concrete negative examples.
- **Alternatives considered**:
  - Two-tier (Small vs. Full) without Medium: rejected because Medium provides a safety buffer for uncertain classifications.
  - Parallel LIGHTWEIGHT workflow definition: rejected per critic review — creates maintenance burden and drift risk. Used conditional simplification within existing single workflow instead.
  - Triage before codebase discovery: rejected — classification without evidence is unreliable.
  - LOC-based threshold (≤50 lines): rejected — agents cannot predict LOC before implementation. Used observable criteria instead.
  - Modifying `operating-rules.md` for routing logic: limited to adding context compaction only (a hard constraint), not routing conditionals.
- **Constraints introduced**:
  - Triage must run after discovery, not before.
  - Uncertainty in classification defaults to Medium.
  - Auth, security, schema, breaking changes always force non-Small.
  - Context compaction summaries are mandatory after each phase of multi-phase tasks.
  - Conformance self-checks in skills should be verified before marking work complete.

## 2026-04-10: Prompt cache optimization via four-layer instruction loading order

- **Context**: The playbook already had token-efficiency mechanisms (memory lifecycle, context compaction, selective reads), but no strategy for maximizing prompt cache hit rates across LLM providers. All major providers (Anthropic, OpenAI, Google, local engines) cache prompt prefixes — if consecutive requests share the same prefix bytes, cached tokens are served at 50–90% reduced cost with lower latency. Without a consistent loading order, the same instruction files could be assembled in different orders across requests, causing cache misses even when the content was identical.
- **Decision**: Introduced a four-layer instruction loading order classified by change frequency: Layer 1 (static rules — `operating-rules.md`, `agent-playbook.md`), Layer 2 (stable skills — `AGENTS.md` + selected `skills/*/SKILL.md` in alphabetical order), Layer 3 (semi-stable project state — `DECISIONS.md`, `ARCHITECTURE.md`), Layer 4 (volatile context — session memory, user query, current files). Created `skills/prompt-cache-optimization/SKILL.md` with the full skill definition including canonical skill sets per task type, file size guidelines, provider-specific notes, and tool-specific adaptation patterns.
- **Alternatives considered**: Rely solely on Claude Code's built-in cache optimization — rejected because the team uses multiple models and tools, so a provider-specific solution leaves other tools unoptimized. Manual per-request cache hint annotations — rejected because it requires API-level changes and is not portable across providers. No action (rely on natural prefix overlap) — rejected because without an enforced order, skill load order varies by task, fragmenting the cache.
- **Constraints introduced**: Instruction files must always be loaded in layer order (1 → 2 → 3 → 4); skills within Layer 2 must be loaded in alphabetical order by directory name for the same task type; per-request content must not be injected into Layer 1 or 2; single instruction files should stay under 8 KB; DECISIONS.md archive thresholds from `memory-and-state` skill are now also cache-relevant constraints.

## 2026-04-10: Cross-file deduplication, tool definition stability, and conversation memory tiering

- **Context**: A prompt efficiency audit found ~4,050 tokens of redundant content across source-of-truth files. The same concepts (three-layer architecture, checkpoint gates, compliance block, instruction loading order, decision archive lifecycle) were fully defined in multiple files instead of using a single source with cross-references. Additionally, the playbook had no guidance on tool/function schema stability (tool definitions are part of the prompt prefix) and no conversation memory tiering strategy (short-term window, mid-term summary, long-term retrieval).
- **Decision**: Three changes: (1) **Deduplication** — collapsed duplicate definitions across `AGENTS.md`, `docs/operating-rules.md`, `docs/agent-playbook.md`, and `.github/copilot-instructions.md` so each concept has exactly one source of truth with other files using brief references + links. (2) **Tool definition stability** — added a section to `skills/prompt-cache-optimization/SKILL.md` covering fixed tool sets per task type, deterministic ordering, stable schemas, and the tool registry pattern for custom API callers. (3) **Conversation memory tiering** — added a section to `skills/memory-and-state/SKILL.md` defining three tiers: short-term (3–5 raw turns), mid-term (compressed summaries integrating with context compaction), long-term (persistent file reads with optional RAG/vector DB), with a total budget guideline of ~8,500 tokens.
- **Alternatives considered**: Create a separate `skills/conversation-memory/SKILL.md` — rejected because conversation memory is a subset of the existing memory-and-state skill and splitting would increase file count without adding clarity. Move tool definitions into a new `skills/tool-management/SKILL.md` — rejected because tool stability is a cache optimization concern, not a standalone skill. Keep duplicated content for "readability at each entry point" — rejected because the token cost (~4,050 per request) outweighs the convenience, and cross-references are sufficient for navigation.
- **Constraints introduced**: Each concept must have exactly one source-of-truth file; other files reference it with a one-line summary + link. Tool schemas must be loaded in alphabetical order and restricted to the task-type subset. Conversation memory must respect the three-tier model with a total budget of ~8,500 tokens.

## 2026-04-10: Adoption-time prompt budget trimming and format template extraction

- **Context**: The full template consumes ~13,000–17,000 tokens per request (Layer 1+2+3). When adopted by downstream projects, much of this content may be unused — roles the project never invokes, skills that do not match the workflow, and format templates that duplicate operating rules already in Layer 1. Every execution consumes significant tokens, and there was no guidance for adopters to self-trim.
- **Decision**: Three changes: (1) **Format template extraction** — moved four verbose format blocks (checkpoint, handoff artifact, context anchor, deliverable structure) from `docs/operating-rules.md` to `docs/agent-templates.md`. Operating-rules now contains one-line descriptions with references to agent-templates. This saves ~500 tokens from Layer 1 (loaded in every request) at the cost of an extra read when full format is needed. (2) **Adoption-time trimming guide** — added a "Prompt budget trimming" section to `docs/adoption-guide.md` with five concrete steps: remove unused roles, remove unused skills, simplify format templates, configure Layer 2 loading strategy, and set up `prompt-budget.yml`. Includes impact estimates (5,000–10,000 tokens savings for aggressive trims). (3) **`prompt-budget.yml` configuration** — added a schema and agent usage rules to `skills/prompt-cache-optimization/SKILL.md`. Projects declare enabled/disabled roles/skills and token budget targets; agents read this file during skill loading and demand-triage to respect the declared budget.
- **Alternatives considered**: Hardcode trimming into the template itself (remove all optional content) — rejected because different projects need different subsets; the template should be complete and let adopters trim. Auto-detect unused skills via static analysis — rejected because skill usage is runtime/prompt-dependent, not statically analyzable. Token budget enforcement at the API layer — rejected because most LLM providers do not support prompt-level budget caps; guidance-level configuration is the pragmatic approach.
- **Constraints introduced**: Format templates in `docs/operating-rules.md` are now one-line references; full formats live in `docs/agent-templates.md`. Adopting projects should create `prompt-budget.yml` if they want to declare a token budget. Agent-templates.md Common preamble is replaced with a compact note referencing operating-rules.md to avoid duplication.
