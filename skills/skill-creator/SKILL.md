---
name: skill-creator
description: Use to generate a new SKILL.md file from a user-described capability. Meta-skill for extending the playbook when a recurring workflow gap is identified.
---

# Skill Creator

Use this skill when a recurring workflow pattern has been identified but no existing skill covers it. This skill produces a new `skills/<name>/SKILL.md` file following the standard structure.

## When to use

- The self-evolution protocol identifies a new skill need (not just a rule or wording change)
- A user explicitly requests a new reusable skill
- A feedback loop mini retrospective flags the same friction 3+ times and the friction maps to a missing reusable capability

## Pre-conditions

Before generating a skill:

1. **Search existing skills** — verify no current skill already covers the capability (check `skills/*/SKILL.md` names and descriptions).
2. **Confirm scope** — the capability must be reusable across at least 2 task types or 2 roles. One-off procedures should remain in `docs/agent-templates.md` as templates, not skills.
3. **User approval required** — skill creation always requires human approval regardless of trust level (same rule as evolution proposals in `docs/operating-rules.md` → Self-evolution guardrails).

## Generation procedure

### Step 1: Define the skill boundary

Produce a brief specification before writing any content:

```text
Skill name: <kebab-case, e.g., api-contract-review>
Description: <one sentence — what this skill does and when to use it>
Trigger condition: <when should this skill activate>
Activation tier: <Always | Conditional | On-demand>
Estimated token cost: <low ~500 | medium ~1500 | high ~3000>
Roles that use it: <which roles invoke this skill>
```

Present the specification to the user for approval before proceeding.

### Step 2: Generate the SKILL.md

Use this skeleton:

```markdown
---
name: <skill-name>
description: <one-sentence description matching the spec>
---

# <Skill Title>

Use this skill to <purpose>.

## When to run

<Trigger condition and scale-based adaptation>

## Procedure

<Numbered steps>

## Conformance self-check

- [ ] <Verification item 1>
- [ ] <Verification item 2>

## Use this skill when

<Bullet list of activation scenarios>
```

Ensure the generated skill follows existing patterns:

- Frontmatter must include `name` and `description` fields.
- Include a "Conformance self-check" section with checkbox items.
- Include a "Use this skill when" section at the end.
- Reference other skills or docs by relative path, not absolute.

### Step 3: Integration checklist

After generating the skill file, complete these updates in the same task:

- [ ] Create `skills/<name>/SKILL.md`
- [ ] Add to `docs/agent-playbook.md` → Skill activation tiers (correct tier table)
- [ ] Add to `prompt-budget.yml` → `skills.on_demand` (default tier for new skills)
- [ ] Update skill count in `AGENTS.md` and `docs/agent-playbook.md`
- [ ] Update `CHANGELOG.md`
- [ ] If the skill is Conditional: document the trigger condition in the Conditional tier table

### Step 4: Validation

- [ ] The generated SKILL.md has valid frontmatter (`name` and `description`)
- [ ] The skill does not duplicate an existing skill's coverage
- [ ] The estimated token cost is documented in the specification
- [ ] All integration checklist items are addressed
- [ ] Markdown lint passes on the new file

## Constraints

- **Maximum 1 new skill per evolution cycle** — creating skills is expensive in token terms; batch creation risks bloat. This limit is a subset of the 3-proposal cap in `docs/operating-rules.md` → Self-evolution guardrails (maximum 3 proposals per cycle, of which at most 1 may be a new skill).
- **On-demand by default** — new skills start as On-demand until proven valuable enough to promote to Conditional or Always.
- **Evergreen review** — if a generated skill is not used within 10 tasks, it should be reviewed for removal during the next quality signal review.

## Conformance self-check

- [ ] Searched existing skills before generating
- [ ] Confirmed reusability across 2+ task types or roles
- [ ] User approved the skill specification
- [ ] Generated file follows the standard SKILL.md skeleton
- [ ] Integration checklist completed (playbook, budget, changelog updated)

## Use this skill when

- Self-evolution identifies a missing reusable capability
- User requests a new workflow skill
- Recurring friction maps to a gap in the current skill set
