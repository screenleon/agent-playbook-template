---
name: test-and-fix-loop
description: Use after writing or modifying code to enforce the mandatory write → test → fix → repeat validation cycle.
depends_on:
  - demand-triage   # scale determines testing intensity
  - repo-exploration # need to know which test commands exist
commonly_followed_by:
  - error-recovery   # invoked when the fix loop reaches 3 failed attempts
  - observability    # emit trace after loop converges
rules:
  - rules/global/test-coverage-spec.md  # MFT/INV/DIR category definitions
---

# Test and Fix Loop

Use this skill to enforce iterative validation after every code change.

## The loop

```text
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

## Scale-adapted testing strategy

Adapt testing intensity based on the task scale from the `demand-triage` skill:

### Small tasks

- Run **only the tests for the changed file** and its direct dependents
- If no tests exist for the file, run the nearest module-level test suite
- A manual smoke check description is acceptable if no automated tests cover the change
- Still follow the fix loop if any test fails

### Medium tasks

- Run the **module-level test suite** covering all changed files
- Run lint/static analysis on changed files
- If the change adds new behavior, at least one new test is expected

### Large tasks

- Run the **full project test suite**
- Run full lint/static analysis
- New tests are mandatory for all new behavior
- Integration tests are expected if the change crosses module boundaries
- Consider running performance-sensitive tests if the change affects hot paths

## Test category classification

Before writing any test, classify each planned test case into exactly one category.
This step runs before the test-first guidance below. See `rules/global/test-coverage-spec.md`
for full definitions and conflict-resolution rules.

| Category | Primary assertion | Typical signal |
|---|---|---|
| **MFT** (Functional) | Correct output for valid input | Return value, side effect, state change |
| **INV** (Stability) | A property holds regardless of input or repetition | No crash, no state corruption, idempotent result |
| **DIR** (Decision Logic) | Correct decision at a branch point | Auth rejection, rate-limit, validation refusal, routing |

### Classification workflow

```text
For each test case to write:
  1. State the primary assertion in one sentence
  2. Match to MFT / INV / DIR using the table above
     - If unsure between INV and DIR: "Is the system enforcing a policy, or merely surviving?"
       Policy enforcement → DIR. Survival → INV.
  3. Label the test with its category before writing it
  4. After all tests are written, list coverage per category
     - Small tasks: one category is sufficient
     - Medium tasks: at least two categories (MFT always; add INV or DIR as applicable)
     - Large tasks: all three categories (waive one only with written justification)
  5. For any absent category, state the reason in the structured preamble or as a
     header comment block in the test file — not in the test name or silently omitted
     Valid waiver: "INV absent — login is intentionally non-idempotent; repeated calls
       create new sessions by design."
     Invalid waiver: "INV: N/A" or leaving the category unlisted entirely
```

### Classification examples

| Scenario | Category | Reason |
|---|---|---|
| `POST /users` returns `201` with `id` on valid payload | MFT | Correct output for valid input |
| `POST /users` with `name: null` does not panic | INV | Survival, not policy |
| Same payload sent twice does not create a duplicate | INV | Idempotency invariant |
| Missing `Authorization` header returns `401` | DIR | Policy enforcement |
| Expired token returns `403` | DIR | Auth boundary decision |
| Payload over size limit returns `413` | DIR | Validation boundary decision |

## Test-first guidance

When adding new behavior (not fixing a bug in existing code), consider writing test expectations before implementation:

1. **Define expected behavior** — write a test that describes what the new code should do
2. **Run the test** — verify it fails for the right reason (missing implementation, not a test bug)
3. **Implement** — write the minimal code to make the test pass
4. **Refine** — add edge case tests, then adjust implementation as needed

### Step → verify pattern

For multi-step tasks, use an explicit verification plan before starting. This format transforms imperative instructions into verifiable goals:

```text
1. [Step description] → verify: [concrete check]
2. [Step description] → verify: [concrete check]
3. [Step description] → verify: [concrete check]
```

Examples of strong vs. weak verification:

| Weak (vague) | Strong (verifiable) |
|---|---|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after, diff shows no behavior change" |
| "Make it work" | "Endpoint returns 200 with expected JSON; integration test passes" |

Strong success criteria let the agent loop independently. Weak criteria require constant clarification.

This is a **recommendation, not a mandate**. Use test-first when:
- The expected behavior is clear and can be expressed as assertions before coding
- The change is a new function, endpoint, or feature (not a refactor or bug fix)
- The project has good test infrastructure that makes writing tests easy

Do not force test-first when:
- The change is exploratory and the API shape is still being discovered
- The test infrastructure would require significant setup to write a meaningful test
- The task is classified as Small and the change is trivial (e.g., config value update)

## Identifying the test command

Check in order:

1. `Makefile` or `Taskfile.yml` → look for `test`, `lint`, `check` targets
2. `package.json` → `scripts.test`, `scripts.lint`
3. `pyproject.toml` / `setup.cfg` → pytest configuration
4. `go.mod` → `go test ./...`
5. `Cargo.toml` → `cargo test`
6. `pom.xml` / `build.gradle` → `mvn test` / `gradle test`
7. Repository documentation (for example `README.md`, `CONTRIBUTING.md`, or the adoption guide) → validation or verification commands

If no test command is identifiable, state that explicitly.

## Use this skill when

- You have just written or modified code
- A previous code generation did not include a verification step
- The user reports that generated code does not compile or pass tests

## How to know it's working (auditable)

All conditions below must be verifiable from task artifacts:

- **Execution evidence**: output lists executed test/lint commands, not planned commands.
- **Loop evidence**: each failed run is followed by a fix and re-run until pass or escalation.
- **Escalation evidence**: recurring error is escalated after 3 failed attempts with attempt history.
- **Final-state evidence**: output reports test counts/results and remaining warnings.

## Conformance self-check

- [ ] Each test case was assigned a category (MFT / INV / DIR) before being written
- [ ] No test spans more than one category — single-category constraint satisfied
- [ ] Coverage per category was listed after test generation (Medium: ≥ 2 categories; Large: ≥ 3)
- [ ] Any absent category was stated with justification, not silently omitted
- [ ] Tests were actually executed (not just planned)
- [ ] The test scope matches the task scale (Small: targeted, Medium: module, Large: full suite)
- [ ] All failures were addressed (fixed or escalated), not silently ignored
- [ ] The final test state is reported (tests run, pass count, warnings)
- [ ] No tests were deleted or disabled to achieve a passing state

## Common misuses

- **Running too broad a test suite for Small tasks** — running the full CI suite for a one-line change wastes time and obscures signal. Use the narrowest scope first.
- **Accepting a passing test after deleting the failing test** — a passing green bar is not evidence of correctness if tests were removed to achieve it.
- **Stopping after the first passing run** — always run lint after tests pass, and confirm neither introduces new warnings.
- **Treating `not-run` as `pass`** — if no test command is found, the skip must be explicitly noted in the trace. It does not count as a passing validation.
- **Counting a no-op re-run as a fix attempt** — if the second attempt is identical to the first, it is not a new attempt; it is wasted time. Change the approach before re-running.
