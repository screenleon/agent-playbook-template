# Decision Log

This file records active architectural and behavioral decisions for this repository.
Agents must read it before planning or implementation tasks.

## 2026-04-27: Introduce GCOMM-001–003 and GCODE-005–006 as core global rules

- **Context**: Research into Karpathy's coding principles, LLM wiki pattern, and autoresearch autonomous-loop design identified four gaps in the existing rule set: (1) no rule preventing sycophancy or fabrication, (2) no explicit advance/discard decision framework for autonomous loops, (3) no guidance for session reset after repeated correction failures, and (4) no periodic rule-quality audit mechanism.
- **Decision**: Add `rules/global/communication-baseline.md` (GCOMM-001–003), extend `rules/global/coding-discipline.md` with GCODE-005–006, and add `skills/rule-lint/SKILL.md`. All rules are marked `core` stability and are adapter-neutral.
- **Alternatives considered**: Mark as `behavior` stability instead of `core` — rejected because anti-fabrication (GCOMM-002) and the autonomous-loop gate (GCODE-005) are safety-adjacent and must not be silently overridden. Keep as agent-native behavior — rejected because these failure modes recur in production without explicit rules.
- **Constraints introduced**: GCOMM-001 prohibits empty affirmation openers; project-layer overrides may restore courtesy phrasing for customer-facing outputs (see `MIGRATION.md`). GCODE-006's two-failure threshold governs user-prompted correction loops only; the operating-rules three-failure stuck-escalation gate governs autonomous validation loops — these are independent counters. GCODE-005's discard step using `git restore .` (uncommitted changes) does not require the destructive-action gate; `git reset --hard` (committed history) does.

## 2026-04-19: Project-local constraints live in the manifest

- **Context**: Repo-local constraints were split between `project/project-manifest.md` and the placeholder `Project-specific constraints` section in `docs/operating-rules.md`. That made discovery and adoption less clear.
- **Decision**: Treat `project/project-manifest.md` as the canonical location for repo-local constraints, validation commands, and operational boundaries. `docs/operating-rules.md` stays generic and points to the manifest.
- **Alternatives considered**: Keep constraints duplicated in both files; keep using `docs/operating-rules.md` as the active location. Both were rejected because duplication causes drift and the project layer already exists for this purpose.
- **Constraints introduced**: New repo-local constraints should be written in the manifest. References to project-specific constraints should prefer the manifest over `docs/operating-rules.md`.

## 2026-04-19: Template repo ships starter governance automation

- **Context**: The repository defined CI review and adoption checks, but key pieces were placeholders. This reduced trust in the workflow.
- **Decision**: Ship minimal working automation: `scripts/agent-review.sh`, `scripts/adoption-audit.sh`, and a sample `.agent-trace` artifact.
- **Alternatives considered**: Leave the scripts as adoption-time placeholders; add a heavier validator with external dependencies. The first kept the workflow incomplete and the second added unnecessary setup cost.
- **Constraints introduced**: Governance automation should remain lightweight, shell-based, and runnable in CI without additional runtimes.
