# Decision Archive

Historical decisions from the agent-playbook-template development.
This file records template-internal decisions that are no longer active
or that predate the current stable release. Adopters do not need to read
this file; it exists for template maintainers and auditors.

---

## 2026-04-19: Template repo ships starter governance automation

- **Context**: The repository defined CI review and adoption checks, but key pieces were placeholders. This reduced trust in the workflow.
- **Decision**: Ship minimal working automation: `scripts/agent-review.sh`, `scripts/adoption-audit.sh`, and a sample `.agent-trace` artifact.
- **Alternatives considered**: Leave the scripts as adoption-time placeholders; add a heavier validator with external dependencies. The first kept the workflow incomplete and the second added unnecessary setup cost.
- **Constraints introduced**: Governance automation should remain lightweight, shell-based, and runnable in CI without additional runtimes.

## 2026-04-19: Project-local constraints live in the manifest

- **Context**: Repo-local constraints were split between `project/project-manifest.md` and the placeholder `Project-specific constraints` section in `docs/operating-rules.md`. That made discovery and adoption less clear.
- **Decision**: Treat `project/project-manifest.md` as the canonical location for repo-local constraints, validation commands, and operational boundaries. `docs/operating-rules.md` stays generic and points to the manifest.
- **Alternatives considered**: Keep constraints duplicated in both files; keep using `docs/operating-rules.md` as the active location. Both were rejected because duplication causes drift and the project layer already exists for this purpose.
- **Constraints introduced**: New repo-local constraints should be written in the manifest. References to project-specific constraints should prefer the manifest over `docs/operating-rules.md`.
