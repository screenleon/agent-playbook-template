---
name: feature-planning
description: Use when a request needs system-level planning before implementation, especially for cross-module, high-risk, or ambiguous work.
depends_on:
  - demand-triage    # scale must be Medium or Large before full planning is warranted
  - repo-exploration # codebase structure required before producing impacted-modules list
  - memory-and-state # DECISIONS.md contradiction check is mandatory before planning
commonly_followed_by:
  - backend-change-planning  # when plan includes schema, contract, or permission changes
  - application-implementation # implementer receives plan as handoff artifact
  - critic                   # critic reviews plan before user approval
---

# Feature Planning

Use this skill to turn a request into a concrete implementation plan before code changes start.

## Pre-planning checklist

Before producing the plan:

1. Read `DECISIONS.md` — check for prior decisions that affect this work
2. Identify contradictions — if the request conflicts with an existing decision, flag it immediately
3. State assumptions, constraints, and proposed approach explicitly

## Output checklist

Always produce:

1. objective
2. non-goals
3. impacted modules
4. user flow
5. API / contract impact
6. DB / migration impact
7. state / UI / navigation impact
8. permissions / security / audit impact
9. implementation order
10. test plan
11. risks
12. open questions

Every item must be addressed. If an item does not apply, write "N/A — [reason]" instead of omitting it.

This checklist should remain consistent with the planning guidance in `.claude/agents/feature-planner.md` and `docs/agent-templates.md`, while allowing this skill to keep its own structure. If guidance differs, follow the documented precedence order: `docs/operating-rules.md` for mandatory rules first, then `docs/agent-playbook.md` for playbook guidance.

## How to decompose modules

When identifying impacted modules (checklist item 3), follow this process:

1. **Trace the user action** — start from the UI trigger (button click, API call, cron job) and follow the call chain through handlers, services, repositories, and external integrations.
2. **List touched boundaries** — for each layer crossed (e.g., controller → service → repository → database), record the file or module.
3. **Mark shared dependencies** — identify types, interfaces, or utilities used by more than one module. Changes to shared code widen the blast radius.
4. **Draw the dependency direction** — note which module depends on which. Changes should flow from leaf (no dependents) toward root (many dependents), not the reverse.
5. **Group by deployability** — if the system has separately deployable units (services, packages, apps), note which units are affected. A plan that touches multiple deployable units is inherently higher risk.

Output format:

```markdown
### Impacted modules
| Module / path          | Role in change          | Depends on       | Depended on by     |
|------------------------|-------------------------|------------------|--------------------|
| src/api/orders.ts      | New endpoint            | src/services/... | (external clients) |
| src/services/order.ts  | New business logic      | src/repos/...    | src/api/orders.ts  |
| ...                    | ...                     | ...              | ...                |
```

## How to define validation criteria

When producing the test plan (checklist item 10), go beyond "write tests". Define:

1. **Happy path** — the core user flow succeeds end-to-end. What input? What expected output or state change?
2. **Edge cases** — boundary values, empty inputs, maximum sizes, concurrent access, duplicate requests.
3. **Error paths** — what happens when a dependency fails (DB down, API timeout, invalid input)? Expected error codes and messages.
4. **Permission boundaries** — can an unauthorized user trigger this? What happens if they try?
5. **Regression anchors** — which existing tests must still pass unchanged? List specific test files or names.
6. **Integration verification** — if the feature crosses module boundaries, define at least one integration test that exercises the full chain.

Output format:

```markdown
### Test plan
| Scenario               | Type        | Input / precondition          | Expected outcome          |
|------------------------|-------------|-------------------------------|---------------------------|
| Create order (happy)   | Unit        | Valid payload, auth'd user    | 201, order in DB          |
| Create order (no auth) | Unit        | Valid payload, no token       | 401 Unauthorized          |
| Create order (dup)     | Integration | Same idempotency key twice    | 409 or same response      |
| ...                    | ...         | ...                           | ...                       |
```

## How to assess risk

Include a dedicated `Risks` section before the separate `Open questions` section, and evaluate each risk with:

1. **Likelihood** — how probable is this risk? (high / medium / low)
2. **Impact** — if it happens, how severe? (high / medium / low)
3. **Mitigation** — what can be done to reduce the risk before or during implementation?
4. **Owner** — who is responsible for watching this risk? (planner, implementer, reviewer, user)

Common risk categories to check:

- **Data loss** — can a migration or schema change lose existing data?
- **Breaking change** — does a contract change break existing consumers?
- **Performance** — does the change introduce N+1 queries, unbounded loops, or missing indexes?
- **Security** — does the change expose new attack surface or weaken existing protections?
- **Rollback difficulty** — can this change be reverted safely, or is it a one-way door?

Output format:

```markdown
### Risks
| Risk                           | Likelihood | Impact | Mitigation                        | Owner    |
|--------------------------------|------------|--------|-----------------------------------|----------|
| Migration drops column in use  | Low        | High   | Add column first, backfill, then remove | Backend  |
| New endpoint lacks rate limit  | Medium     | Medium | Add rate limit before launch      | Reviewer |
| ...                            | ...        | ...    | ...                               | ...      |
```

## How to know it's working (auditable)

All conditions below must be verifiable from the plan artifact:

- **Completeness evidence**: all 12 checklist items are present (or N/A with reason).
- **Implementation readiness evidence**: implementation order is numbered and executable without missing dependencies.
- **Testability evidence**: each test scenario includes type, input/precondition, and expected outcome.
- **Risk evidence**: each risk entry includes likelihood, impact, mitigation, and owner.

## How to define implementation order

When specifying the implementation order (checklist item 9):

1. **Schema first** — migrations must be applied before code that depends on new columns or tables.
2. **Contracts second** — API types, interfaces, and shared DTOs before the code that uses them.
3. **Core logic third** — services and business logic before handlers, controllers, or UI.
4. **Integration fourth** — wiring, navigation, and state management after core logic is stable.
5. **Tests alongside** — each step above should include its own tests before moving to the next.

Numbering the steps ensures implementation agents know "do not start step N until step N-1 passes validation."

## Request early risk review

For plans that involve any of the following, request a risk-reviewer assessment **before** presenting the plan to the user for approval:

- Schema migrations on production data
- Permission or auth model changes
- Changes to payment, billing, or financial logic
- Deleting or renaming public API endpoints
- Cross-service or cross-deployment changes

This is in addition to the regular risk-reviewer pass that happens after implementation.

## Mandatory checkpoint

After producing the plan:

If the current trust level activates the plan-approval gate, **STOP** and present the plan to the user for explicit approval.

If the gate outcome is **ADVISORY** or **PASS** for the current trust level, record that outcome and continue without waiting.

If the user requests changes, revise and present again.

## Use this skill when

- more than one module is affected
- contract or schema changes are likely
- auth, permissions, upload, audit, or security are involved
- the user asks for planning, sequencing, scope, or risk analysis

## Conformance self-check

Before presenting the plan to the user, verify:

- [ ] All 12 output checklist items are addressed (N/A with reason if not applicable)
- [ ] `DECISIONS.md` was read and no contradictions exist
- [ ] Assumptions, constraints, and proposed approach are explicitly stated

## Common misuses

- **Producing a plan without reading DECISIONS.md** — the contradiction check is mandatory. A plan that conflicts with a prior decision will be rejected, wasting the planning effort.
- **Marking items as N/A without a reason** — `N/A` is only valid with a documented reason. "N/A" alone makes the plan unauditable and is not accepted by the conformance check.
- **Bundling multiple features into one plan** — a single plan for a compound request creates compound risk. If the request contains two separate features, produce two separate plans.
- **Understating the risk section** — omitting a risk because it feels embarrassing to name it is the most common way risks end up in production. Every plan must have at least one risk entry with likelihood, impact, and mitigation.
- **Presenting a plan before the critic reviews it** — for Medium and Large tasks, the critic must review the plan before it is presented to the user for approval. Skipping this step removes a key quality gate.
- [ ] The test plan covers happy path, edge cases, error paths, and permission boundaries
- [ ] Risks include likelihood, impact, and mitigation for each
- [ ] Implementation order follows the canonical sequence (schema → contracts → logic → wiring → tests)
- [ ] The plan does not quietly expand beyond the original request
