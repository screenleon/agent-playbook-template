---
name: error-recovery
description: Use when encountering compile errors, test failures, runtime exceptions, or unexpected behavior during implementation.
depends_on:
  - test-and-fix-loop  # error-recovery is invoked when test-and-fix-loop cannot self-resolve
commonly_followed_by:
  - test-and-fix-loop  # re-enter the fix loop after applying the recovery step
  - observability      # record escalation in trace if escalating to user
---

# Error Recovery

Use this skill when something goes wrong during implementation.

## Triage protocol

### Step 1: Classify the error

| Type | Examples | Priority |
|------|----------|----------|
| Compile / build error | Missing import, type mismatch, syntax error | Fix immediately |
| Test failure | Assertion failed, timeout, unexpected output | Fix immediately |
| Lint / static analysis | Unused variable, style violation | Fix before marking done |
| Runtime error | Panic, null pointer, unhandled exception | Fix immediately |
| Logic error | Wrong output, missing edge case | Investigate then fix |

### Step 2: Read the full error

- Do not guess from partial output or error summaries.
- Read the complete error message, stack trace, and any related log output.
- Identify: file, line number, error type, and the immediate cause.

### Step 3: Identify root cause

- Trace the error backward from the symptom to the source.
- Check: is this a problem in your new code, or did it expose a pre-existing issue?
- Check: did you violate a project-specific constraint?

### Step 4: Fix minimally

- Change only what is needed to resolve the error.
- Do not refactor, improve, or clean up unrelated code during error recovery.
- If the fix requires changing test expectations, explain why the new expectation is correct.

### Step 5: Re-verify

- Re-run the exact command that produced the error.
- If it passes, run the broader test suite to check for regressions.
- If it fails again, use the **failure-family check** below to decide
  whether this counts as the "same failure" for escalation purposes.

### Step 5a: Failure-family check (all adapters)

The "3 attempts then escalate" rule counts *same-family* failures only.
Cosmetic differences (line numbers, timestamps, memory addresses, stack
depth) do not reset the counter — the underlying problem is the same.

Before retrying, save each attempt's raw error output to a temp file and
call the reference detector:

```bash
bash harness/core/failure-family-detect.sh attempt-N.log attempt-N+1.log
# exit 0 → same family (do NOT reset counter)
# exit 1 → different family (reset counter, continue)
# exit 2 → unknown / empty input (treat as same family; do not reset)
```

The script classifies errors into 7 families (`test_failure`, `lint`,
`build_error`, `exception`, `schema_error`, `auth_error`, `infra_error`).
It is adapter-neutral — any runtime can shell out to it. If your runtime
cannot run shell scripts, emulate the classification natively and record
the result in `failure_families[]` on your trace (see
`docs/schemas/trace.schema.yaml`).

Record each attempt's family in the trace so reviewers can audit the
escalation decision:

```yaml
failure_families:
  - { attempt: 1, family: test_failure, same_as_previous: false }
  - { attempt: 2, family: test_failure, same_as_previous: true }
  - { attempt: 3, family: test_failure, same_as_previous: true }  # escalate
```

### Step 6: Escalate if stuck

If 3 *same-family* fix attempts fail, report to the user:

```text
Error: [exact error message]
File: [file:line]
Attempts:
1. [what you tried] → [result]
2. [what you tried] → [result]
3. [what you tried] → [result]
Hypothesis: [what you think the underlying issue is]
Suggested next step: [what a human should check]
```

## Anti-patterns

- **Do not** silently ignore errors or warnings.
- **Do not** remove or skip failing tests to make the suite pass.
- **Do not** add `// nolint`, `@SuppressWarnings`, or equivalent without justification.
- **Do not** broaden a type (e.g., `any`) to avoid a type error.
- **Do not** catch and swallow exceptions to hide failures.

## Use this skill when

- A test fails after your code change
- The build does not compile
- You see unexpected runtime behavior
- Static analysis reports new warnings

## How to know it's working (auditable)

All conditions below must be verifiable from task artifacts:

- **Full-error evidence**: output includes exact failing command and primary error location (`file:line`).
- **Attempt log evidence**: each retry records action and result; max 3 *same-family* attempts before escalation.
- **Family classification evidence**: when any retry happens, the trace's `failure_families[]` records the detected family per attempt and the `same_as_previous` flag.
- **Minimal-fix evidence**: changed files map to error path; unrelated edits are absent or justified.
- **Escalation evidence**: if escalated, report includes error, attempts, hypothesis, and next step.

## Conformance self-check

- [ ] The full error message was read (not guessed from partial output)
- [ ] Root cause was identified and stated
- [ ] The fix was minimal (no unrelated changes bundled)
- [ ] Re-verification was run and passed
- [ ] When retries occurred: the failure-family check ran (shell or native) and the result was recorded in the trace
- [ ] If escalated: the escalation report includes error message, attempts, hypothesis, and suggested next step

## Common misuses

- **Retrying the same fix without changing the approach** — if attempt 1 failed, attempt 2 must be meaningfully different. Identical retries are not counted toward the 3-attempt limit.
- **Treating a workaround as a fix** — suppressing an error (e.g., adding `// nolint`, catching and ignoring an exception) without resolving the root cause is a workaround, not a fix. Document it as such.
- **Fixing symptoms instead of root cause** — e.g., adding a null check to suppress a NullPointerException without understanding why the value is null. The symptom fix may pass tests while the real bug remains.
- **Over-fixing during recovery** — changing unrelated code during a fix attempt introduces new risk and makes it harder to isolate what caused the original error.
- **Escalating before 3 attempts on genuinely recoverable errors** — not every error needs a human. Escalate only when the pattern is stuck (same failure family, no material reduction).
