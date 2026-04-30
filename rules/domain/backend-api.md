# Domain Template: Backend API Rules

Use this template for backend API constraints reusable across repositories.

## Rule entries

Repeat this block for each rule.

```markdown
### Rule: <RULE_ID>
- Owner layer: Domain
- Domain: backend-api
- Stability: <core | behavior | experimental>
- Status: active
- Scope: <module or surface>
- Directive: <clear non-negotiable rule>
- Rationale: <why>
- Conflict handling: <what overrides this rule or when to escalate>
- Example: <positive example>
- Non-example: <what this rule forbids or does not cover>
- Supersedes: <RULE_ID or N/A>
- Superseded by: <RULE_ID or N/A>
```

## Starter examples

### Rule: API-001

- Owner layer: Domain
- Domain: backend-api
- Stability: core
- Status: active
- Scope: public HTTP handlers
- Directive: All API responses must follow a single envelope contract.
- Rationale: Consumer compatibility and consistent error handling.
- Conflict handling: Project rules may name the concrete envelope fields, but may not allow handler-specific response shapes without a documented compatibility reason.
- Example: Success and error responses both include the documented envelope fields, and integration tests assert those fields.
- Non-example: One endpoint returns a raw database object while another returns `{ data, error }`.
- Supersedes: N/A
- Superseded by: N/A

### Rule: API-002

- Owner layer: Domain
- Domain: backend-api
- Stability: core
- Status: active
- Scope: backward-compatible endpoint evolution
- Directive: Additive changes are allowed; breaking schema changes require versioning.
- Rationale: Prevent client breakage.
- Conflict handling: A project may define a deprecation window or migration policy, but cannot ship a breaking contract change silently.
- Example: Add a nullable response field under the current version; create a new version before removing or renaming an existing field.
- Non-example: Rename a response property in place and rely on clients to adapt.
- Supersedes: N/A
- Superseded by: N/A
