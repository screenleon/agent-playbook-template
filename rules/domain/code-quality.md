# Domain Rules: Code Quality

Cross-domain code quality rules applicable to all technical domains (backend API,
frontend components, cloud infrastructure, and any other coding context).

These rules capture repository-specific coding behavior that is reusable across
projects but dependent on per-repo style conventions — and therefore appropriately
placed at the Domain layer rather than Global.

Load this file alongside `docs/operating-rules.md` and
`rules/global/code-quality-baseline.md` at `standard` and `full` budget profiles.

## Rule entries

### Rule: DCODE-001

- Owner layer: Domain
- Domain: code-quality (all technical domains)
- Stability: behavior
- Status: active
- Scope: all code modification tasks on existing files
- Directive: When modifying existing code, change only the lines required by the task. Preserve existing style, naming conventions, formatting, and idioms even when a different approach would be preferred. Do not refactor, rename, or reorganize code that is not part of the stated task. Remove only imports, variables, or functions that your own changes directly orphaned; leave pre-existing dead code intact unless the task explicitly requests cleanup.
- Rationale: Unrequested style changes and refactors contaminate diffs, make code review harder, and introduce regression risk in unrelated paths. Ownership of pre-existing dead code is ambiguous — it may be referenced by external tools, scripts, or in-flight branches. Style preservation is repo-specific; project teams often have conventions that differ from the agent's preferences, and overriding them silently erodes trust.
- Conflict handling: If correctness requires a broader refactor, state the reason and trigger the scope-expansion checkpoint before editing unrelated code.
- Example: Fix the requested function and update only the imports orphaned by that fix.
- Non-example: Rename neighboring variables, reformat the file, and remove old unused helpers while fixing an unrelated bug.
- Supersedes: N/A
- Superseded by: N/A
