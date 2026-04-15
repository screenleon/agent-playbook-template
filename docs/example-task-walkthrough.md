# Example Task Walkthrough

This document shows a complete task from initial request to final delivery, demonstrating the required workflow artifacts in a way that matches the current source-of-truth rules.

It also demonstrates a common pattern introduced in the playbook: the **same role** can move from `analyze` to `implement` without switching agents, as long as the task scale and risk level allow a shared context.

**Scenario**: Expose an existing `last_login` timestamp in the user profile API response.

---

## Step 1 — Codebase discovery

_Agent reads relevant files before anything else. Outputs a brief summary of what was found._

```text
Files read: src/api/users.ts, src/repos/user.ts, db/queries/user.sql,
            src/api/users.test.ts, DECISIONS.md, ARCHITECTURE.md
Patterns identified:
  - All handlers in src/api/ follow the Express router pattern
  - Repository queries are defined in db/queries/user.sql and consumed through src/repos/user.ts
  - API responses use the envelope format defined in docs/api-envelope.md
  - The database already stores last_login; it is simply not exposed in the current query/response
```

---

## Step 2 — Demand triage

_Agent classifies scale after discovery, not before. Provides explicit evidence._

```text
[SCALE: MEDIUM]
Reason: Affects 3 implementation files and 1 targeted test in the same module.
        No schema change, no auth change, no destructive action.
        Public API response shape changes, so this is larger than a Small single-file edit.
Files affected: db/queries/user.sql, src/repos/user.ts,
                src/api/users.ts, src/api/users.test.ts
```

---

## Step 3 — First-response compliance block

_Shown here because this is a Medium task. Small tasks at `semi-auto` or `autonomous` may keep this implicit per the operating rules._

```text
Read set: src/api/users.ts, src/repos/user.ts, db/queries/user.sql,
          src/api/users.test.ts, DECISIONS.md, ARCHITECTURE.md,
          docs/operating-rules.md (project-specific constraints)
Scale: [SCALE: MEDIUM] — bounded cross-file API response update, no schema/auth changes
Role: application-implementer
Current intent mode: analyze
Workflow path: Medium bounded application change → application-implementer
  (`analyze` → `implement` in same context) → risk-reviewer
Checkpoint map:
  - Plan approval: not required for bounded Medium change with clear scope
  - Destructive actions: none
  - Scope expansion: STOP if the change requires auth, middleware, or schema updates
```

---

## Step 4 — Structured preamble

_Assumptions, constraints, and proposed approach stated before any code._

**Role**: `application-implementer`

**Intent mode**: `analyze`

**Assumptions**:
- `last_login` is already persisted correctly by the auth flow
- The response envelope stays unchanged; only the `data` payload changes
- Existing consumers tolerate additive fields in the response body

**Constraints** (from DECISIONS.md and operating-rules):
- Keep the existing SQL query + repository + handler layering
- Keep the shared response envelope format
- Do not expand into auth or schema work in this task

**Proposed approach**:
1. Update the existing user query to select `last_login`
2. Surface the field through the repository type
3. Add `last_login` to the handler response and targeted test coverage

---

## Step 5 — DECISIONS.md contradiction check

_The contradiction check always runs. This example states it explicitly because the task is Medium; streamlined Small paths may keep a clean result implicit._

```text
Contradiction check result: No contradictions found.
  - Existing decision "Use the API envelope format" is respected.
  - Existing query/repository layering is preserved.
  - No active decision forbids additive response fields on user-profile reads.
```

---

## Step 6 — Analyze-phase output and mode transition

_The same role finishes analysis, narrows the scope, and explicitly switches to implementation without spawning a new agent._

```text
Analyze result:
- The database field already exists; no migration or planner-led schema path is needed.
- The change remains bounded to query, repository type, handler, and targeted tests.
- No new checkpoint is activated because the role is unchanged and scope remains within the original request.

Mode transition:
- Role: application-implementer
- From intent mode: analyze
- To intent mode: implement
- New agent required: No
- Reason: bounded Medium task, same role, no scope expansion, no new approval gate
- Approved scope:
  - db/queries/user.sql
  - src/repos/user.ts
  - src/api/users.ts
  - src/api/users.test.ts
```

---

## Step 7 — Implementation

_Agent writes code. For this bounded Medium task, the application-implementer remains the active role._

```sql
-- db/queries/user.sql (updated query)
-- name: GetUser :one
SELECT id, email, name, created_at, last_login
FROM users
WHERE id = $1;
```

```typescript
// src/repos/user.ts — updated result type
export type User = {
  id: string;
  email: string;
  name: string;
  created_at: Date;
  last_login: Date | null;
};
```

```typescript
// src/api/users.ts — updated handler
router.get('/:id', async (req, res) => {
  const user = await userRepo.getUser(req.params.id);
  if (!user) return res.status(404).json(envelope(null, 'User not found'));
  return res.json(envelope({
    id: user.id,
    email: user.email,
    name: user.name,
    created_at: user.created_at,
    last_login: user.last_login,
  }));
});
```

```typescript
// src/api/users.test.ts — targeted test addition
it('includes last_login in the user response', async () => {
  const response = await request(app).get('/users/123');
  expect(response.status).toBe(200);
  expect(response.body.data).toHaveProperty('last_login');
});
```

---

## Step 8 — Validation loop

_Agent runs tests after every code change. Results must be reported explicitly._

```text
Command run: npm test -- --testPathPattern=users
Result: 8 passed, 0 failed
  ✓ GET /users/:id returns 200 with user object
  ✓ GET /users/:id returns 404 for unknown id
  ✓ GET /users/:id includes last_login field   ← new test
  ✓ POST /users creates user without mutating last_login
  ... 4 more existing tests passing

Lint: npm run lint — 0 errors, 0 warnings
Type check: tsc --noEmit — 0 errors
```

---

## Step 9 — Handoff to risk-reviewer

_The implementation role is complete. Review uses a different role, so the workflow switches context through a structured handoff artifact instead of raw conversation history._

```text
## Handoff: application-implementer → risk-reviewer
- **Source intent mode**: implement
- **Target intent mode**: review
- **Task**: Verify the additive `last_login` response-field change for bugs, regressions, and missing tests.
- **Deliverable**: Updated query, repository type, handler response, and targeted API test coverage.
- **Key decisions**: Preserve existing query/repository/handler layering; keep the response-envelope contract unchanged while extending the payload.
- **Open risks**: Existing external clients may ignore or unexpectedly depend on the new field once released.
- **Constraints for next step**: Review is read-only. Do not expand scope into auth, migrations, or unrelated profile fields.
- **Attached output**: Validation results show targeted tests, lint, and typecheck all passing.
```

---

## Step 10 — Risk review

_The review role leads with findings. In this example, no blocking findings are discovered._

```markdown
## Review: Expose last_login on user profile API

### Findings
- None.

### Open questions / assumptions
- None.

### Residual risks
- External consumers may begin relying on the new field once it is visible.
- No end-to-end client compatibility test was added for downstream consumers because this task was limited to the service itself.

### Summary
- No findings. Downstream consumer compatibility remains the main residual risk.
```

---

## Step 11 — DECISIONS.md entry

_A new entry is appended because the public API response contract changed, even though the change is additive._

```markdown
## 2026-04-15: Expose last_login on user profile reads
- **Context**: The service already stores `last_login`, but the user profile API did not expose it to clients that need to show recent-account activity.
- **Decision**: Extend `GET /users/:id` to include nullable `last_login` in the response payload while preserving the existing response envelope.
- **Alternatives considered**: Keep the field internal only; add a separate endpoint just for login metadata.
- **Constraints introduced**: Future profile readers should treat `last_login` as part of the public response contract and preserve nullability for users without login history.
```

---

## Step 12 — Deliverable

_Every non-review role produces this structure. Medium tasks fill it in fully._

```markdown
## Deliverable: Expose last_login on user profile API

### Proposal
Expose the existing nullable `last_login` field in `GET /users/:id` by updating the query, repository type, handler response, and targeted tests.

### Alternatives considered
- Keep `last_login` internal only — rejected because the profile experience needs it.
- Add a second endpoint for login metadata — rejected because it would split data that already belongs to the primary profile read.

### Pros / Cons
| Pros | Cons |
|------|------|
| Bounded cross-file change | Public response contract expands |
| No schema or auth changes required | Downstream consumers may start depending on the field |
| Preserves existing envelope and layering | |

### Risks
- Additive contract changes can still affect strict clients (low likelihood, medium impact). Mitigation: document the field and preserve nullability.

### Recommendation
Ship as described and record the new response-field contract in `DECISIONS.md`.
```

---

## Step 13 — Task completion summary

_Required after every task. Enables memory reuse across sessions._

```markdown
## Task summary
- Scale: MEDIUM
- What changed: Exposed nullable `last_login` on `GET /users/:id`.
- Files modified: db/queries/user.sql, src/repos/user.ts, src/api/users.ts, src/api/users.test.ts, DECISIONS.md
- Key decisions: `last_login` is now part of the public profile-read contract.
- Pattern learned: bounded response-shape changes can stay in one application-implementer context if they do not cross into schema/auth work.
- Tests: npm test -- --testPathPattern=users — 8 passed, 0 failed
- Open items: Document the field in external API reference docs if the project keeps separate consumer-facing docs.
```

---

## Step 14 — Trace

_Trace is mandatory for completed tasks. Medium tasks emit a structured trace artifact._

```yaml
# .agent-trace/2026-04-15-last-login-profile.yaml
task: expose-last-login-on-user-profile-read
date: "2026-04-15"
scale: Medium
trust_level: semi-auto
isolation_status: clean
roles_invoked:
  - application-implementer
  - risk-reviewer
skills_loaded:
  - demand-triage
  - repo-exploration
  - test-and-fix-loop
  - error-recovery
  - memory-and-state
  - prompt-cache-optimization
  - self-reflection
  - observability
files_changed:
  - db/queries/user.sql
  - src/repos/user.ts
  - src/api/users.ts
  - src/api/users.test.ts
  - DECISIONS.md
decisions_made:
  - "2026-04-15: Expose last_login on user profile reads"
validation_outcome: pass
reflection_summary:
  correctness: pass
  consistency: pass
  adherence: pass
  completeness: pass
risks_accepted:
  - "External consumers may begin relying on last_login once it is visible"
```

---

## Step 15 — Mini retrospective

_Required at the end of every task. Feeds into the rolling quality signals._

```text
Friction observed: It was easy to treat an additive response field as "too small to document," but the contract-change rule correctly forced a decision-log update.
Miss risk: The easiest mistake would have been forgetting to update the targeted API test while changing only the query and handler.
Most useful rule: Explicit analyze → implement mode transition kept the bounded Medium path clear without forcing an unnecessary planner handoff.
Next improvement: Add a reusable checklist snippet for additive API response changes so contract updates and docs sync are less easy to miss.
```

---

## What this example demonstrates

| Required output | Where shown |
|----------------|-------------|
| Compliance block | Step 3 |
| Demand triage with evidence | Step 2 |
| Structured preamble | Step 4 |
| DECISIONS.md contradiction check | Step 5 |
| Same-role analyze → implement transition | Step 6 |
| Validation loop result | Step 8 |
| Handoff artifact with intent modes | Step 9 |
| Review output | Step 10 |
| DECISIONS.md decision entry | Step 11 |
| Mandatory deliverable structure | Step 12 |
| Task completion summary | Step 13 |
| Trace artifact | Step 14 |
| Mini retrospective | Step 15 |

### Formats referenced

The deliverable, handoff, task summary, trace expectations, and mini retrospective templates are defined in `docs/agent-templates.md` and the referenced skill docs. The compliance-block rules and required fields are defined in `docs/operating-rules.md` → Mandatory first-response compliance block. The routing logic that determines which agent roles are used is in `docs/agent-playbook.md`.
