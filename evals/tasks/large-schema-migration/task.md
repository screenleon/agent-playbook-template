# Task: Large — add a soft-delete column to the users table

Introduce soft-delete semantics for the `users` table. This involves:

- Adding a `deleted_at TIMESTAMP NULL` column via migration.
- Updating the repository/DAO layer to filter out soft-deleted rows by default.
- Updating any service-layer code that reads users to respect the filter.
- Updating at least one UI surface that lists users to ignore deleted rows.
- Writing migration-safety notes for rollback.

## Scope

- Crosses DB → service → UI layers.
- Public API contract for GET /users changes its effective result set.
- Tests must cover: new insert, update, soft-delete, query-with-deleted, rollback.

## Your task

Plan first. Get the plan critiqued. Then implement in the correct order
(schema → contract → logic → UI). Emit a full trace describing each role's
step and the gates that activated.
