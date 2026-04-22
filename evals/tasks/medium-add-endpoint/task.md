# Task: Medium — add a status endpoint

Add a new GET /status endpoint to a backend service. The endpoint should:

- Return `{"status": "ok", "version": "<semver>"}` as JSON.
- Not require authentication.
- Be covered by at least one integration test.
- Follow the service's existing handler pattern.

## Scope

- Affects 2–5 files within the same service module (handler + route + test).
- No schema changes, no auth changes, no breaking changes.
- Existing endpoints must continue to work.

## Your task

Plan the change briefly, implement it, add the test, and run validation.
Emit a trace describing roles invoked and the decisions you made.
