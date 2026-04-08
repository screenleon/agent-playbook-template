---
name: memory-and-state
description: Use to maintain persistent context across agent sessions — decision logs, architecture memory, and constraint tracking.
---

# Memory and State

Use this skill to prevent agents from forgetting prior decisions and repeating mistakes.

## Three memory layers

### 1. Decision log (`DECISIONS.md`)

A version-controlled file at the repo root. Records architectural and behavioral decisions.

Format:

```markdown
## YYYY-MM-DD: [Decision title]
- **Context**: Why this decision was needed
- **Decision**: What was decided
- **Alternatives considered**: What was rejected and why
- **Constraints introduced**: What future work must respect
```

Rules:
- Read `DECISIONS.md` at the start of every planning or implementation task. This is not optional.
- Append to it when making a decision that future work depends on.
- Never silently contradict an existing decision — either follow it or propose a reversal with user approval.
- When appending, verify the new entry does not conflict with existing entries.

### 2. Architecture memory (`ARCHITECTURE.md`)

A version-controlled file describing the codebase structure.

Should contain:
- Module map (directory → purpose)
- Key interfaces and their contracts
- Data flow overview
- External service dependencies
- Known technical debt

Rules:
- Read before working on unfamiliar modules.
- Update when structural changes are made (new modules, moved files, changed boundaries).

### 3. Session-scoped working memory

For in-progress tasks that span multiple agent interactions:

- Use session notes or scratch files to track:
  - What has been done so far
  - What remains
  - Errors encountered and how they were resolved
  - Open questions

This prevents re-discovery and reduces repeated mistakes within a session.

## Context anchor protocol

For any task spanning more than one step or more than one file, maintain a context anchor using the canonical template in `docs/operating-rules.md`.

Do not duplicate or redefine the template here; treat `docs/operating-rules.md` as the single source of truth for the anchor format and fields.

Update this anchor before each major step. This prevents drift by forcing the agent to re-read the plan and current state.

## Contradiction detection

Before making any decision, check `DECISIONS.md` for conflicts:

1. Read the full decision log
2. Compare each existing entry against the proposed change
3. If a conflict exists, present it using this format:

```markdown
## Contradiction detected
- **Existing decision**: [date and title]
- **Proposed change**: [what the current task wants to do]
- **Conflict**: [why these are incompatible]
- **Options**: (a) follow existing decision, (b) reverse existing decision with justification
```

STOP and wait for user decision. Do not resolve contradictions autonomously.

## When to write memory

| Event | Action |
|-------|--------|
| Architectural decision made | Append to `DECISIONS.md` |
| New module or structural change | Update `ARCHITECTURE.md` |
| Constraint discovered during work | Add to `Project-specific constraints` in `docs/operating-rules.md` |
| Error pattern found | Note in session memory to avoid repeating |
| Task partially complete | Write progress to session notes |
| Technology or library introduced | Append to `DECISIONS.md` |
| Schema or contract changed | Append to `DECISIONS.md` |
| Tradeoff made | Append to `DECISIONS.md` |

## When to read memory

| Event | Action |
|-------|--------|
| Starting any implementation | Read `DECISIONS.md` and `ARCHITECTURE.md` |
| Encountering unfamiliar module | Read `ARCHITECTURE.md` |
| Making a decision | Check `DECISIONS.md` for prior related decisions |
| Resuming interrupted work | Read session notes |
| Starting a long task | Produce a context anchor |
| Starting a Small task | Query categorized memory for similar past patterns (see below) |

## Categorized memory structure

Organize persistent memory into categories to enable efficient retrieval, especially for Small tasks where speed matters:

### Project-level memory

Architectural decisions, global conventions, technology choices, build/deploy patterns.

- Primary store: `DECISIONS.md`, `ARCHITECTURE.md`
- Query when: starting any task, making architectural choices

### Component-level memory

Per-module patterns, common conventions, known quirks, module-specific constraints.

- Primary store: inline comments, module READMEs, session notes, or repo memory files
- Query when: working on a specific module, especially an unfamiliar one
- How to search: look for session notes or repo memory files related to the module name or directory path

### Change-pattern memory

Recurring task patterns — how similar small changes were handled before, common fix patterns, validated approaches.

- Primary store: session notes or repo memory files
- Query when: starting a Small task — check if a similar change has been done before and reuse the approach
- Write when: completing a task that establishes a reusable pattern (captured in the task completion summary)
- How to search: look for session notes or repo memory containing keywords from the current task type (e.g., "validation", "config update", "copy change")

### Memory retrieval for Small tasks

When the `demand-triage` skill classifies a task as Small, **before implementing**, check for similar past changes:

1. Search session notes and repo memory for the affected module name or file path
2. Search for keywords matching the task type (e.g., "add validation", "fix typo", "update config")
3. If a matching pattern is found, follow it rather than re-analyzing from scratch
4. If no match exists, proceed normally — then capture the pattern in the task completion summary

## Memory lifecycle management

Persistent memory files grow over time. Without active lifecycle management, they consume excessive tokens on every read and eventually exceed context windows.

### Decision archive (cold storage)

#### When to archive

- `DECISIONS.md` exceeds **50 entries** or **30 KB**, OR
- Any memory health indicator (see below) reaches the "needs attention" threshold, OR
- During periodic maintenance review (quarterly for low-volume projects; more frequently when thresholds are hit)

#### Archive procedure

1. Review each entry in `DECISIONS.md`
2. For each entry, check: **are the constraints introduced still actively referenced by current code or docs?**
3. If the constraints are **no longer active** (the code has moved on, the pattern was replaced, etc.), move the entry to `DECISIONS_ARCHIVE.md`
4. If the constraints are **still enforced**, keep the entry in `DECISIONS.md`

Never archive based on date alone — a 2-year-old decision with active constraints stays in `DECISIONS.md`.

#### Archive file format

```markdown
# Decision Archive

Archived decisions that no longer constrain current work.
For active decisions, see `DECISIONS.md`.

<!-- Each entry keeps its original format and date. -->
<!-- Add "Archived on: YYYY-MM-DD" and reason below each entry. -->

## YYYY-MM-DD: [Original decision title]
- **Context**: [original]
- **Decision**: [original]
- **Alternatives considered**: [original]
- **Constraints introduced**: [original]
- **Archived on**: YYYY-MM-DD — [why this is no longer active, e.g., "replaced by decision X" or "feature removed"]
```

#### Safety checks before archiving

- [ ] Every entry marked for archive has constraints that are verifiably no longer enforced
- [ ] No current code imports, references, or depends on the archived pattern
- [ ] The archive entry includes the reason it was archived
- [ ] `DECISIONS.md` still contains all decisions with active constraints after the move

### Selective read strategy

Agents should not read the full archive on every task. Use a tiered approach:

| Situation | What to read |
|-----------|-------------|
| Normal task | `DECISIONS.md` only (active constraints) |
| Task involves legacy module or old migration | `DECISIONS.md` + search `DECISIONS_ARCHIVE.md` for module name |
| Contradiction detection finds no match in active | Search `DECISIONS_ARCHIVE.md` before concluding "no prior decision" |
| Periodic maintenance review | Read both files in full |

### Session memory hygiene

Session-scoped memory (scratch notes, in-progress tracking) should not accumulate without bound.

#### Promotion rule

After task completion, promote session memory to repo-level memory **only if**:

- The pattern was reused 2+ times in different tasks, OR
- The feedback loop mini retrospective flagged it as "most useful"

All other session notes are disposable after the task completion summary is produced.

#### Cleanup cadence

- At the end of each task: review session notes, promote or discard
- At the end of each week (or every 10 tasks): purge session memory that was not promoted

### Memory health indicators

Track during feedback loop quality signal reviews:

| Indicator | Healthy | Needs attention |
|-----------|---------|-----------------|
| `DECISIONS.md` entry count | ≤ 50 | > 50 without recent archive |
| `DECISIONS_ARCHIVE.md` exists | Yes, once any archiving has occurred | No, with 50+ active decisions |
| Session memory files | ≤ 5 active | > 10 without cleanup |
| Stale constraint references | 0 | Any archived constraint still referenced in code |

## Context compaction protocol

Long tasks cause context to grow, increasing cost and reducing model accuracy. Use compaction to prevent this.

### When to compact

- After completing each **phase** of a multi-phase task (e.g., after planning, after each implementation group)
- When the conversation has exceeded **10+ back-and-forth exchanges** on the same task
- Before handing off to a different agent role (produce a handoff artifact — this is also a form of compaction)
- When you notice yourself re-reading earlier messages to remember what was decided

### Compaction procedure

1. **Produce a progress summary** capturing:
   - What has been completed
   - Key decisions made (with `DECISIONS.md` references if applicable)
   - Current state of the work
   - What remains to be done
   - Any errors encountered and how they were resolved

2. **Store the summary** in session memory or working notes

3. **Continue from the summary**, not from the full conversation history

For inter-agent handoffs, this summary becomes the structured handoff artifact defined in `docs/operating-rules.md`.

### Post-task summary

After completing any task (regardless of scale), produce a task completion summary using the template in `docs/agent-templates.md` → Task completion summary. That template is the single source of truth for the summary format.

For Small tasks: if the summary includes a reusable pattern, store it in session or repo memory for future reuse.
For Medium/Large tasks: the summary also feeds into documentation sync checks.

## Use this skill when

- Starting work on a repository for the first time
- Making decisions that affect future work
- Resuming work after a break
- Noticing that an agent is repeating a previously resolved mistake
- Working on a task that spans more than one step or file
