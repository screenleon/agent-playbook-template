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
- Read `DECISIONS.md` at the start of every planning or implementation task.
- Append to it when making a decision that future work depends on.
- Never silently contradict an existing decision — either follow it or propose a reversal.

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

## When to write memory

| Event | Action |
|-------|--------|
| Architectural decision made | Append to `DECISIONS.md` |
| New module or structural change | Update `ARCHITECTURE.md` |
| Constraint discovered during work | Add to `Project-specific constraints` in `docs/operating-rules.md` |
| Error pattern found | Note in session memory to avoid repeating |
| Task partially complete | Write progress to session notes |

## When to read memory

| Event | Action |
|-------|--------|
| Starting any implementation | Read `DECISIONS.md` and `ARCHITECTURE.md` |
| Encountering unfamiliar module | Read `ARCHITECTURE.md` |
| Making a decision | Check `DECISIONS.md` for prior related decisions |
| Resuming interrupted work | Read session notes |

## Use this skill when

- Starting work on a repository for the first time
- Making decisions that affect future work
- Resuming work after a break
- Noticing that an agent is repeating a previously resolved mistake
