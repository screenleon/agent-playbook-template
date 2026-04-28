---
name: ubiquitous-language
description: Use to establish and maintain a shared domain glossary (UBIQUITOUS_LANGUAGE.md). Creates a single source of term definitions that all agents, prompts, and documents must use — preventing semantic drift and repeated re-explanation across sessions.
commonly_followed_by:
  - feature-planning
  - documentation-architecture
---

# Ubiquitous Language

Use this skill to build and maintain a shared semantic layer for the project. A term defined here is the canonical term — all agents, all prompts, all documents use it consistently. No synonyms, no informal aliases, no per-session re-interpretation.

## Why this is not documentation

Documentation describes what exists. This skill defines what words mean.

Without a shared semantic layer:
- The same concept gets different names across agents and sessions ("order" vs "cart" vs "purchase")
- Agents re-interpret terms each session ("context" means something different in three different prompts)
- Token budget is wasted re-explaining terms that should already be shared vocabulary
- Agents produce structurally correct but semantically inconsistent outputs that require manual reconciliation

With a shared semantic layer:
- Every agent starts from the same definitions
- Design discussions are unambiguous — "order" means exactly one thing
- New agents can be briefed in one load of `UBIQUITOUS_LANGUAGE.md`
- Contradictions between sessions surface as glossary conflicts, not silent bugs

## When to run

Run this skill when:
- Starting a new project (triggered by `on-project-start`)
- A new domain concept appears in a plan or design that has no existing definition
- Two agents or two sessions use different words for the same concept
- A term is used ambiguously across prompts, plans, or documents

## Creating UBIQUITOUS_LANGUAGE.md

Create the file at the repo root as `UBIQUITOUS_LANGUAGE.md`.

Required structure:

```markdown
# Ubiquitous Language

> All agents, prompts, and documents in this project use the terms below exactly as defined.
> Do not introduce synonyms. If a term is missing, add it here before using a new word.

## [Domain Area]

### [Term]
[One-sentence definition — what this concept represents in the domain.]
**Distinct from:** [near-synonyms this could be confused with, and why they differ]
**Example:** [one concrete example in context]
```

Rules for each entry:
- Definition is one sentence. If it requires more, split into two concepts.
- "Distinct from" is mandatory if any synonym or near-synonym exists anywhere in the codebase or docs.
- "Example" grounds the definition — abstract definitions drift.

### Example entries

```markdown
## Order processing

### Order
Represents a user's confirmed purchase intent, from cart confirmation through fulfillment.
**Distinct from:** Cart (pre-confirmation state), Transaction (the payment record)
**Example:** An Order is created when the user submits checkout; a Cart is discarded at that point.

### Context
The temporary in-memory state of an incomplete registration or multi-step form, not yet persisted.
**Distinct from:** Session (browser auth state), Draft (persisted but unpublished record)
**Example:** Context holds company registration fields until the user clicks Submit.

### Template
A JSON schema defining UI field structure and the mapping rules from form input to domain objects.
**Distinct from:** Form (the rendered UI component), Schema (the raw JSON structure without mapping rules)
**Example:** The company registration Template specifies which fields map to which API parameters.

### PriceRule
A named rule that computes a cost modifier given an order context; composed by PriceCalculator.
**Distinct from:** Discount (a specific type of PriceRule with a negative delta), Price (the final computed value)
**Example:** A PriceRule might apply a regional tax or a volume discount based on order quantity.
```

## Maintaining UBIQUITOUS_LANGUAGE.md

Every time a new term appears in a plan, implementation, or design review:

1. Check if the term exists in `UBIQUITOUS_LANGUAGE.md`
2. If it exists — use the exact canonical form, not a synonym
3. If it does not exist — add it before proceeding

Do not wait until after implementation to add terms. A term used in code without a glossary entry is already creating drift.

## Enforcement rules

All agents must:
- Load `UBIQUITOUS_LANGUAGE.md` as part of task context (included in memory-and-state layer)
- Use only canonical terms in all output: plans, code, docs, handoff artifacts
- Flag any term used in the task that is not in the glossary and add it before proceeding

## Synonym resolution

When two terms are discovered for the same concept (via code review, design discussion, or agent output):

1. Pick the canonical term — favor the term used in domain model, user-facing language, or earliest decision
2. Record the deprecated synonym under "Distinct from" with `Deprecated alias: [synonym]`
3. Open a refactor task to replace the deprecated term in code and docs

## How to know it's working (auditable)

- `UBIQUITOUS_LANGUAGE.md` exists at repo root and is committed to version control
- Every domain concept used in plans, code, and docs has an entry
- No two entries have overlapping definitions
- "Distinct from" entries reference each other symmetrically (if A distinguishes itself from B, B's entry mentions A)
- Token cost of context-loading sessions trends down as shared vocabulary accumulates

## Conformance self-check

- [ ] `UBIQUITOUS_LANGUAGE.md` exists at repo root
- [ ] All terms introduced or used in this task are present in the glossary
- [ ] No synonyms are used without an explicit "Deprecated alias" entry
- [ ] New terms added in this session are committed to the glossary before implementation begins
- [ ] "Distinct from" entries are symmetric between related terms
