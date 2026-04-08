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
