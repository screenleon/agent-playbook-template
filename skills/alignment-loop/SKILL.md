---
name: alignment-loop
description: Use before committing to a design or plan to force assumption-surfacing. The agent challenges your design, questions edge cases, and flags gaps — you patch vague decisions. Prevents the failure mode where a design "feels explained" but contains hidden flaws that only appear during implementation.
depends_on:
  - demand-triage
commonly_followed_by:
  - feature-planning
---

# Alignment Loop

Use this skill to surface hidden assumptions and design flaws **before** implementation begins. This is not a discussion — the agent actively challenges your design, identifies gaps, and forces explicit decisions on ambiguous points.

## What this is not

This is not:
- A design review (passive read of your spec)
- A question-and-answer session (waiting for you to volunteer problems)
- A rubber-stamp before implementation

This is:
- Active challenge of design assumptions
- Identification of unstated edge cases and boundary conditions
- Forced resolution of vague or implicit decisions
- A structural guarantee that "it felt explained" ≠ "it was explained"

The most dangerous outcome is an agent that writes confidently wrong code because the design seemed clear. This skill exists to prevent that.

## When to run

Run alignment-loop when:
- You have a design idea, feature spec, or system change you want to commit to
- You are about to delegate implementation to an agent
- The task is Medium or Large scale (demand-triage output)
- The design crosses module boundaries or introduces new domain concepts

Do **not** skip this step because the design feels obvious. The most dangerous designs are the ones that feel obvious to the designer.

## Protocol

### Phase 1 — Initial challenge (agent-driven)

The agent reads the design proposal and produces a challenge list. For each challenge, the agent must name a **specific failure scenario** — not a rhetorical question. "Have you considered X?" is not a challenge. "The design breaks under X because Y — what is the explicit decision?" is.

Challenge categories:

1. **Assumption violations** — what assumption is required for this to work? What breaks if that assumption is wrong?
2. **Boundary conditions** — what happens at the edges: empty state, maximum scale, concurrent access, zero-value inputs, expired states?
3. **Unstated decisions** — what choices are implicit in the design that haven't been stated? (naming, ownership, failure behavior, ordering)
4. **Contradiction check** — does any part of the design conflict with existing decisions in `DECISIONS.md` or the codebase?
5. **Scope creep risk** — does the design quietly pull in concerns that belong to other modules or future work?

Challenge output format:

```markdown
## Alignment challenges

### [C1] <short label>
**Category:** [Assumption | Boundary | Unstated | Contradiction | Scope]
**Failure scenario:** [what breaks and how, concretely]
**Forced decision:** [what explicit choice the designer must make to resolve this]

### [C2] ...
```

### Phase 2 — Designer response

For each challenge, the designer must respond with exactly one of:

- **Accept** — the design already handles this; explain how
- **Patch** — the design did not handle this; state the explicit decision now
- **Defer** — this is out of scope; state why and name who owns it

No challenge may be left without a response. "We'll handle it later" without an explicit Defer entry is not accepted. Defer requires an explicit reason and owner.

### Phase 3 — Closure check

After all challenges are resolved, the agent produces a closure summary:

```markdown
## Alignment closure

- Challenges raised: N
- Accepted (design handles it): N
- Patched (explicit decision added): N
- Deferred (out of scope, documented): N
- Unresolved: 0
```

If unresolved items remain, the loop does not close. Repeat Phase 1–2 on the unresolved items only.

## Mandatory checkpoint

After closure:

- All **Patched** decisions must be recorded before feature-planning begins. Where to record them depends on `decision_log.policy` in `prompt-budget.yml`:
  - `normal` — append to `DECISIONS.md`
  - `example_only` — record in the task summary, handoff artifact, or trace file instead
- All **Deferred** items must appear in the plan's `open questions` section.
- The closure summary must be included in the handoff artifact to the feature-planner.

## How to know it's working (auditable)

- Every challenge has a labeled response (Accept / Patch / Defer)
- Every Patch adds an explicit, named decision recorded in `DECISIONS.md`
- Every Defer names an owner and a reason
- Closure count is consistent (accepted + patched + deferred = total raised)
- Zero unresolved items before proceeding to feature-planning

## Autonomous mode behavior

When `execution_mode: autonomous` is set in `prompt-budget.yml`, Phase 2 (Designer response) has no human in the loop. The agent must self-resolve challenges using one of these strategies:

1. **Accept** — if the design clearly handles the challenge, accept and document the reasoning
2. **Patch** — if a gap is identified, apply the most conservative explicit decision and record it
3. **Defer** — if the challenge requires human judgment, treat it as a hard stop and escalate (same behavior as Gate 2 destructive actions: stop and request input)

In autonomous mode, challenges that cannot be Accept/Patch resolved without human input become escalation triggers. They do not silently close.

## Common failure modes

- **Soft challenges**: Agent asks "Have you considered X?" instead of naming a specific failure scenario. Reject these — require a concrete failure scenario for every challenge.
- **Designer deflection**: "We'll figure it out later" without a proper Defer entry. Treat deflection as an open Patch until an explicit decision is recorded.
- **Skipping on Medium tasks**: Medium-scale tasks crossing module boundaries always warrant at least Phase 1 + Phase 2. The abbreviated version still requires challenge → response pairs.
- **Running after implementation starts**: Alignment-loop is a pre-implementation gate. Running it mid-implementation creates conflicts with existing code. If already past implementation, use the `critic` role instead.

## Conformance self-check

Before closing the alignment loop, verify:

- [ ] Every challenge is categorized (Assumption / Boundary / Unstated / Contradiction / Scope)
- [ ] Every challenge states a specific failure scenario, not a rhetorical question
- [ ] Every challenge has a labeled response (Accept / Patch / Defer)
- [ ] All Patches result in explicit decisions recorded in `DECISIONS.md`
- [ ] All Defers name an owner and a reason
- [ ] Closure summary counts are consistent with individual responses
- [ ] Zero unresolved items before handing off to feature-planning
