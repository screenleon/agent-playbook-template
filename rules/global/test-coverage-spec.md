# Global Test Coverage Spec

Rules that govern how test cases are classified and generated. These rules apply
before any test is written, across all domains and adapters.

Load this file alongside `rules/global/code-quality-baseline.md` and
`skills/test-and-fix-loop/SKILL.md` whenever the task involves writing or reviewing tests.

## Rules

### Rule: GTCS-001

- Owner layer: Global
- Scope: all tasks that involve writing or generating tests
- Stability: behavior
- Status: active
- Directive: Before writing any test case, classify it into exactly one category — MFT, INV, or DIR — and state that label explicitly. Do not generate tests without a declared category. If a test case seems to span two categories, choose the one that reflects the primary assertion; do not split the test to satisfy both.
- Rationale: Unclassified tests accumulate without coverage intent. When tests are written without a declared purpose, gaps in functional, stability, or decision coverage become invisible until a real failure surfaces them. Forcing a single category per test also prevents the common failure mode of writing one test that tries to assert too many concerns at once.
- Conflict handling: When a test case genuinely cannot be assigned to a single category without losing its meaning, escalate to the user for clarification before writing the test. Do not default to MFT — that bias causes INV and DIR coverage to be chronically under-represented.
- Example: A test that verifies an API endpoint returns the correct JSON body → MFT. A test that verifies the same endpoint rejects an unauthenticated request → DIR. These are two separate tests, each with a single declared category.
- Non-example: A single test that calls the endpoint, checks the response body, asserts no crash on null input, and verifies the auth header is required — four concerns collapsed into one unnamed test.

### Rule: GTCS-002

- Owner layer: Global
- Scope: all test generation tasks
- Stability: behavior
- Status: active
- Directive: Apply the following definitions to classify each test case. Each category has a distinct primary assertion type:
  - **MFT (Functional)**: The system produces the correct output for a given valid input. The assertion targets the return value, side effect, or state change that the feature promises.
  - **INV (Stability)**: A property of the system holds regardless of input, order, or repetition. The assertion targets an invariant — the system must not crash, must not corrupt state, must return a consistent type, or must remain idempotent across repeated calls.
  - **DIR (Decision Logic)**: The system makes the correct decision at a branch point. The assertion targets which path was taken — including acceptance/rejection, routing, permission enforcement, and boundary-guard responses such as authorization failures, rate-limit rejections, and input validation refusals.
- Rationale: Ambiguous category definitions cause misclassification drift. Explicit definitions make the classification mechanical enough to audit and reviewable enough to challenge. DIR explicitly covers boundary guards (auth, rate-limit, validation refusals) because these are decision outcomes, not stability properties — the system is not merely "not crashing"; it is actively enforcing a policy.
- Conflict handling: When unsure between INV and DIR: ask "Is the system enforcing a policy decision, or merely surviving?" Policy enforcement → DIR. Survival → INV.
- Example: `POST /users` with valid payload returns `201` with `id` field → MFT; the same endpoint without `Authorization` returns `401` → DIR.
- Non-example: Label every endpoint test as MFT even when the primary assertion is a permission, validation, or idempotency decision.
- Example (MFT): `POST /users` with valid payload returns `201` with `id` field → MFT.
- Example (INV): `POST /users` called twice with the same payload does not create a duplicate → INV. `POST /users` with `name: null` does not panic → INV.
- Example (DIR): `POST /users` without `Authorization` header returns `401` → DIR. `POST /users` with an expired token returns `403` → DIR. `POST /users` with a payload exceeding the size limit returns `413` → DIR.

### Rule: GTCS-003

- Owner layer: Global
- Scope: test suite composition for Medium and Large tasks
- Stability: behavior
- Status: active
- Directive: For Small tasks, one category is sufficient. For Medium tasks, at least two categories must be covered. For Large tasks, all three categories must be covered. Before declaring test generation complete, list which categories are present and which are absent. A category may be absent only when the feature genuinely has no meaningful assertion in that category; the absence must be stated with a specific reason in the structured preamble or as a header comment block in the test file.
- Rationale: Without a coverage check, agents default to writing MFT-only test suites. INV and DIR tests are consistently underrepresented because they require thinking about failure paths and boundary conditions rather than the happy path. Requiring explicit per-category accounting prevents silent gaps. Specifying the destination for absence statements (preamble or test-file header) makes the waiver auditable rather than discardable.
- Conflict handling: When a feature genuinely cannot produce two categories for a Medium task, waive one by name with a one-sentence reason. A valid waiver names the category and explains why it is structurally inapplicable. An invalid waiver is a bare label ("INV: N/A") or an unlisted category.
- Example: A Medium task adding a new login endpoint → MFT (correct token returned on valid credentials), DIR (invalid password returns 401, missing body returns 400). INV waived with: "INV absent — login is intentionally non-idempotent; repeated calls create new sessions by design." Waiver placed in the structured preamble.
- Non-example: A Large task adding an entire user management module, with only MFT tests written; INV and DIR left unlisted with no preamble entry.
