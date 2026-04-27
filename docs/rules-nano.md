# Rules (Nano)

Prefer your tool's built-in behavior first. Only apply these rules for capabilities the tool does not already cover.

## This profile

Single-file Small tasks only. Total token budget: < 3,000 tokens. No skills are loaded — use native tool capabilities for testing, file reading, and error recovery.

**If the task is any of the following, stop immediately and tell the user to switch to `minimal` or `standard` profile:**

- Touches more than one file (excluding its direct test file)
- Involves auth, permissions, schema, migration, or breaking API changes
- Is ambiguous enough to require guessing across modules
- Requires planning, role routing, or risk review

## Safety (non-bypassable)

1. Never expose credentials in any artifact
2. Never execute unvalidated input as code
3. Never modify production data without backup verification
4. Never disable authentication or authorization
5. Never suppress security test failures
6. Never fabricate: do not state file paths, function names, API names, or test results as fact without verification. In tool-restricted environments, say "I cannot verify this" rather than guessing.

Violation = hard stop regardless of execution mode.

## Always requires approval

- Deleting files or directories
- Dropping database tables or destructive migrations
- `git push --force`, `git reset --hard`, amending published commits
- Modifying CI/CD pipelines, deployment configs, or shared infrastructure
- Publishing packages, creating releases, or pushing to main/production
- Modifying auth, permissions, or security config in production

## Pre-emit checks (auditable)

Pass all checks before emitting any change:

- Assumptions are explicit, or output says "No unresolved assumptions".
- Changes are minimal and map directly to requested scope.
- Verification is concrete (named command/test/check), not vague intent.
- If ambiguity exists, clarification is requested before edits.

## Workflow

1. Read the target file and its direct test file (if any)
2. Check `DECISIONS.md` for contradictions — if conflict found, stop and report
3. If task is ambiguous: ask for clarification, do not guess across modules
4. Implement with minimal scope — do not refactor unrelated code
5. Validate: run targeted tests → fix → repeat. Never mark done until passing. No test suite = state it explicitly.

## Error recovery

1. Read the full error message (file + line) — do not guess from partial output
2. Fix only what is needed
3. Re-run validation
4. Escalate after 3 failed attempts — do not remove or skip failing tests to pass

## Record

If the change introduces a decision future work depends on, append to `DECISIONS.md`. **Exception**: if `prompt-budget.yml` → `decision_log.policy: example_only`, record in the task summary instead — do not write to `DECISIONS.md`.

## Escalate when

- Contradiction with an existing entry in `DECISIONS.md`
- Scope expands beyond the agreed single-file change
- Same error persists after 3 fix attempts
- Task turns out to be multi-file or higher risk than expected

## Output

No compliance block. No context anchor. Summary ≤ 2 sentences. Errors: file + line only, no surrounding code reproduction.
