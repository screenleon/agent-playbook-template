# Multi-Reviewer Orchestration

Use this pattern when one reviewer is not enough for a high-stakes change and
reviewer independence is part of the quality bar. It defines when to use a
single shared review sequence, when to isolate reviewers, and how to synthesize
their outputs into one verdict.

Related source-of-truth rules:

- `docs/operating-rules.md` -> Constitutional principles
- `docs/operating-rules.md` -> Trust level
- `docs/agent-playbook.md` -> Role definitions

## When To Use Multi-Reviewer Gates

Use a multi-reviewer gate for changes where missed defects have high cost or
where one reviewer perspective is too narrow.

Default triggers:

- Auth, permission, payment, billing, migration, audit, or security-model changes
- Any change that can violate a constitutional principle if reviewed incorrectly
- Any change where reviewer independence matters more than token or runtime cost
- Any work that already produced a severity-high finding and now needs re-gating
- Any change promoted by the active trust level into a stricter checkpoint path

Upgrade from a single reviewer to multi-reviewer when at least one is true:

- The change touches more than one critical risk class
- The first review found systemic issues rather than isolated defects
- The implementation changed after review in a way that affects the risk model
- Stakeholders need independent evidence, not only a single consolidated opinion
- The cost of a missed issue is higher than the cost of additional review passes

## Sequential Mode

Sequential mode is the default multi-reviewer gate.

Pattern:

1. All reviewers run in one shared session or shared review context.
2. Reviewers execute in a fixed order.
3. Each later reviewer can see earlier findings.
4. The final output may be produced by the last reviewer or by a lightweight
   synthesis step.

Benefits:

- Lower cost
- Less duplicated context loading
- Faster for routine changes
- Prior findings help later reviewers focus on known concerns

Risk:

- anchoring: later reviewers may overweight earlier findings and miss issues the
  first reviewer missed.

Use sequential mode when:

- The change is routine or low-risk
- Cost sensitivity matters more than independence
- Prior findings are useful context rather than a bias risk
- The active trust level does not require stronger independence

## Parallel Mode

Parallel mode isolates reviewer judgment.

Pattern:

1. Each reviewer receives the same approved scope and evidence bundle.
2. Each reviewer runs in a separate isolated session with no shared reviewer
   findings.
3. Reviewers produce independent outputs.
4. A synthesis step reads all reviewer outputs after they complete.

Benefits:

- Eliminates anchoring between reviewers
- Produces independent evidence for high-stakes decisions
- Improves coverage when different reviewers are expected to notice different
  failure modes

Cost:

- Higher token and runtime cost
- More duplicated context loading
- Requires an explicit synthesis step before a final verdict exists

Use parallel mode when:

- The change affects auth, payments, migrations, audit trails, or security models
- A constitutional principle could be weakened by a missed defect
- Reviewer independence is critical to trust in the outcome
- The active trust level or stakeholder expectation calls for stronger gates
- The team is re-validating a high-risk fix after blocker findings

## Synthesis Step

After parallel reviewers complete, a synthesis agent reads all reviewer outputs
and produces a unified verdict.

Responsibilities:

- Deduplicate equivalent findings
- Preserve independent findings that disagree or expose different risks
- Escalate blockers and severity-high findings
- Separate must-fix issues from advisory risks
- Produce one final verdict: pass, pass with advisories, or block

The synthesis agent should be a PM-class role: analysis and decision framing,
not implementation. It must not silently resolve technical disagreement by
discarding minority findings. When reviewers disagree, the synthesis should name
the disagreement and state what evidence would settle it.

## Reviewer Role Matrix

| Gate type | Reviewer set | Use when |
|---|---|---|
| Express subset | critic, qa-tester | Low-risk changes that still need a second pass |
| Standard set | critic, qa-tester, architecture-reviewer, security-reviewer, risk-reviewer | Normal multi-reviewer gate for meaningful product or framework changes |
| High-stakes parallel set | critic, qa-tester, architecture-reviewer, security-reviewer, risk-reviewer | Auth, payment, migration, audit, security-model, or constitutional-principle-sensitive changes |
| Targeted subset | Only reviewers relevant to the fixed finding | Re-gating after specific findings were fixed |

Targeted subsets are valid only when the fix scope is narrow and does not change
the original risk model. If the fix changes architecture, permissions, data
shape, or security behavior, return to the standard or high-stakes set.

## Decision Table

| Criterion | Sequential | Parallel |
|---|---|---|
| Primary goal | Efficient layered review | Independent reviewer judgment |
| Reviewer context | Shared findings visible in order | Isolated findings until synthesis |
| Cost | Lower | Higher |
| Anchoring risk | Present | Eliminated between reviewers |
| Best for | Routine or cost-sensitive changes | High-risk or independence-critical changes |
| Typical gate strength | Standard checkpoint support | Strong checkpoint evidence |
| Required final step | Optional or lightweight synthesis | Explicit synthesis before verdict |

