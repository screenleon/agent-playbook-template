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
- If it fails again with the same error, try a different approach (max 3 attempts).

### Step 6: Escalate if stuck

If 3 fix attempts fail, report to the user:

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
- **Attempt log evidence**: each retry records action and result; max 3 attempts before escalation.
- **Minimal-fix evidence**: changed files map to error path; unrelated edits are absent or justified.
- **Escalation evidence**: if escalated, report includes error, attempts, hypothesis, and next step.

## Conformance self-check

- [ ] The full error message was read (not guessed from partial output)
- [ ] Root cause was identified and stated
- [ ] The fix was minimal (no unrelated changes bundled)
- [ ] Re-verification was run and passed
- [ ] If escalated: the escalation report includes error message, attempts, hypothesis, and suggested next step

## Common misuses

- **Retrying the same fix without changing the approach** — if attempt 1 failed, attempt 2 must be meaningfully different. Identical retries are not counted toward the 3-attempt limit.
- **Treating a workaround as a fix** — suppressing an error (e.g., adding `// nolint`, catching and ignoring an exception) without resolving the root cause is a workaround, not a fix. Document it as such.
- **Fixing symptoms instead of root cause** — e.g., adding a null check to suppress a NullPointerException without understanding why the value is null. The symptom fix may pass tests while the real bug remains.
- **Over-fixing during recovery** — changing unrelated code during a fix attempt introduces new risk and makes it harder to isolate what caused the original error.
- **Escalating before 3 attempts on genuinely recoverable errors** — not every error needs a human. Escalate only when the pattern is stuck (same failure family, no material reduction).
