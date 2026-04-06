---
name: test-and-fix-loop
description: Use after writing or modifying code to enforce the mandatory write → test → fix → repeat validation cycle.
---

# Test and Fix Loop

Use this skill to enforce iterative validation after every code change.

## The loop

```
┌─────────────┐
│  Write code  │
└──────┬──────┘
       ▼
┌─────────────┐
│  Run tests   │ ← project test command (e.g., go test ./..., npm test, pytest)
└──────┬──────┘
       ▼
┌─────────────┐
│  Run lint    │ ← project lint command (e.g., go vet, eslint, mypy)
└──────┬──────┘
       ▼
   Pass? ──No──► Fix errors (minimal change) ──► Re-run from top
       │
      Yes
       ▼
┌─────────────┐
│    Done      │
└─────────────┘
```

## Rules

1. **Always run tests** — never skip this step, even for "obvious" changes.
2. **Run the narrowest scope first** — test only the affected package/module, then broaden if needed.
3. **Read full error output** — do not guess from truncated messages.
4. **Fix minimally** — change only what the error requires. Do not refactor during the fix cycle.
5. **Max 3 attempts per error** — if the same error persists after 3 fix attempts, escalate to the user.
6. **Never delete tests to pass** — if a test fails, fix the code or update the test expectation with justification.
7. **Report the final state** — after the loop converges, confirm: which tests ran, how many passed, any remaining warnings.

## Identifying the test command

Check in order:

1. `Makefile` or `Taskfile.yml` → look for `test`, `lint`, `check` targets
2. `package.json` → `scripts.test`, `scripts.lint`
3. `pyproject.toml` / `setup.cfg` → pytest configuration
4. `go.mod` → `go test ./...`
5. `Cargo.toml` → `cargo test`
6. `pom.xml` / `build.gradle` → `mvn test` / `gradle test`
7. `docs/operating-rules.md` → `Validation commands` section

If no test command is identifiable, state that explicitly.

## Use this skill when

- You have just written or modified code
- A previous code generation did not include a verification step
- The user reports that generated code does not compile or pass tests
