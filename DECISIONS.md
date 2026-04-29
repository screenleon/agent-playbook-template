# Decision Log

This file records active architectural and behavioral decisions for this repository.
Agents must read it before planning or implementation tasks.

## 2026-04-29: MFT/INV/DIR test category taxonomy (GTCS rules)

- **Context**: The test-and-fix-loop skill guided test execution but not test generation. Agents consistently produced MFT-only test suites, leaving stability (INV) and decision-logic (DIR) coverage invisible until real failures surfaced them.
- **Decision**: Introduce three canonical test categories — MFT (Functional), INV (Stability), DIR (Decision Logic) — as global rules (GTCS-001/002/003). Each test must declare exactly one category before being written. Coverage floors are enforced per task scale: Small (1+), Medium (2+), Large (3). Absent categories must be stated with a specific reason in the structured preamble, not silently omitted.
- **Alternatives considered**: (1) Leave classification implicit in test naming conventions — rejected because naming is too informal to audit. (2) Allow multi-category tests — rejected because collapsed assertions hide which coverage dimension a test serves and produce tests that try to assert too many things at once. (3) Put boundary guards (auth, rate-limit, validation refusals) in INV — rejected because these are active policy decisions, not survival properties; DIR is the correct home.
- **Constraints introduced**: All new test generation must classify each test before writing. Medium tasks must cover ≥2 categories; Large tasks must cover all 3. Waivers require a named reason in the preamble or test-file header comment.

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
