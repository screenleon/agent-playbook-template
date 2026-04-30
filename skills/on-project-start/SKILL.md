---
name: on-project-start
description: Use on first entry to a new repository to run environment scanning and ask targeted boundary questions before implementation.
---

# On Project Start

Use this skill only when entering a repository for the first time in a session, or when project boundaries are still unclear — it converts unknown project boundaries into explicit, confirmed constraints before implementation starts. For returning sessions where boundaries are already confirmed, use the Session Resume Protocol in `skills/memory-and-state/SKILL.md` instead.

## Protocol

1. Scan repository signals
   - Inspect top-level files and dependency manifests (e.g., `package.json`, `pom.xml`, `go.mod`, `requirements.txt`, `Cargo.toml`, `Gemfile`).
   - Detect likely stack and runtime (for example Spring Boot, Django, React, Terraform, CDK).
   - Detect validation commands from CI config (`.github/workflows/`, `Makefile`, `Justfile`, scripts).
   - Check for existing conventions docs (`CONVENTIONS.md`, `ARCHITECTURE.md`, `.editorconfig`).

2. Ask targeted boundary questions

   **First, ask about the budget profile** — this affects every subsequent decision about which skills and rules are loaded:

   > "Which token budget profile fits your setup?
   > - **nano** — < 3,000 total tokens. Single-file Small fixes only. No skills loaded. Best for: extreme token limits, simple patches.
   > - **minimal** — < 16K context. Small tasks only. Loads demand-triage + repo-exploration. Best for: solo devs, tight budgets.
   > - **standard** — 16K–32K context. Small/Medium tasks. Full skill set. Best for: typical team usage. *(default)*
   > - **full** — 32K+ context. All tasks including Large. All skills. Best for: large teams, complex projects."

   Skip this question only if `prompt-budget.yml` already has `budget.profile` explicitly set to a non-default value.

   Then ask only high-value technical questions that can change implementation decisions:
   - Ask only questions whose answers are not already documented in existing project files.
   - Prefer either/or questions when possible.
   - Examples:
     - "I detected Spring Boot. Is there a package naming standard I must follow?"
     - "I detected AWS IaC files. Should infrastructure changes use Terraform or CDK?"
     - "I see no test framework configured. Which testing approach should I use?"

3. Confirm and persist
   - Write the selected budget profile to `prompt-budget.yml` → `budget.profile` (create the file from `docs/prompt-budget-examples.md` if it does not exist yet).
   - Summarize confirmed boundaries in concise bullets.
   - Add or update `project/project-manifest.md` with the confirmed constraints.
   - If a new durable architectural constraint is discovered, record it according to `prompt-budget.yml` -> `decision_log.policy`.

4. Continue with normal workflow
   - Run `repo-exploration` then `demand-triage`.
   - Do not start implementation until initialization questions are resolved or explicitly deferred by user instruction.

## Output format

```text
Initialization summary:
- Budget profile selected: [nano | minimal | standard | full] — written to prompt-budget.yml
- Detected stack:
- Boundary questions asked:
- User confirmations:
- Constraints recorded in project manifest:
- Open items (if any):
```

## Conformance self-check

- [ ] Budget profile was confirmed with user and written to `prompt-budget.yml`
- [ ] Stack signals were discovered from real files, not guessed
- [ ] At least one boundary question was asked when constraints were unclear
- [ ] Confirmed constraints were written to project context
- [ ] Workflow proceeded to discovery/triage before implementation

## Use this skill when

- Entering a repository for the first time in a session
- Project boundaries are unclear and need explicit confirmation
- `prompt-budget.yml` does not yet have `budget.profile` set
