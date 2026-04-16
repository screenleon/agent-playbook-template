# Decision Log

This file records architectural and behavioral decisions that affect future work.
Agents must read this file before planning or implementation tasks.
See `skills/memory-and-state/SKILL.md` for when to read and write.

> **Adopter note**: This file is intentionally blank in the template. Start adding your own decisions from day one. Template development history has been moved to `DECISIONS_ARCHIVE.md` so you inherit a clean log.
>
> The fastest way to get value: keep one entry per architectural choice so every future agent run can perform contradiction checks.

<!-- Append new decisions below using the format shown. -->
<!-- Do not remove or silently contradict existing entries. -->
<!-- To reverse a decision, add a new entry that explicitly references and supersedes the old one. -->

<!-- Template format:
## YYYY-MM-DD: [Decision title]
- **Context**: Why this decision was needed
- **Decision**: What was decided
- **Alternatives considered**: What was rejected and why
- **Constraints introduced**: What future work must respect
-->

---

<!-- Add your real decisions below this line -->

## 2026-04-16: Adopt behavioral self-checks and success indicators

- **Context**: The playbook had rules and skills but lacked inline self-check sentences and observable success indicators. This reduced adherence and made quality hard to audit.
- **Decision**: Integrate three features: (1) four one-line quick self-checks in `rules-quickstart.md` and `rules-nano.md`, (2) "How to know it's working" sections in four core skills, (3) a step → verify pattern in the test-and-fix-loop skill. All adapted to existing structure.
- **Alternatives considered**: (a) Adopt a single-file behavior spec entirely — rejected because the playbook's multi-role, multi-skill architecture provides capabilities that a single file cannot. (b) Add a separate behavior skill file — rejected to avoid another file load; embedding into existing rules/skills is more token-efficient.
- **Constraints introduced**: Self-check sentences must remain concise (≤ 1 line each) to preserve token budgets, especially at `nano` and `minimal` profiles. Success indicator sections must not duplicate conformance self-check lists.

---
