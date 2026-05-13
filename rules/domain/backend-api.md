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

### Rule: API-003

- Owner layer: Domain
- Domain: backend-api
- Stability: core
- Status: active
- Scope: all new features and endpoints crossing a platform or consumer boundary
- Directive: The API contract must be updated and reviewed before implementation begins, using the project's chosen contract format such as OpenAPI, GraphQL schema, gRPC proto, or an equivalent binding contract. Code must match the reviewed contract.
- Rationale: Contract-first development keeps cross-platform consumers such as mobile apps, web frontends, and third-party integrators compatible. Code-first development causes contract drift, where the contract becomes a lagging description of implementation behavior instead of a binding agreement.
- Conflict handling: A project may specify the contract format and tooling, but cannot waive contract-first authoring for features that cross a platform or consumer boundary. For purely internal, single-consumer refactors, the project may define a lighter-weight contract review process.
- Example: Before adding a new search endpoint, update the contract with the request and response schema, have the contract reviewed, then generate types and implement the endpoint.
- Non-example: Implement the endpoint first, then run a generator to retroactively document what was built.
- Supersedes: N/A
- Superseded by: N/A
