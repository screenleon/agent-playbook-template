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
