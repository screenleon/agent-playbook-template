---
name: application-implementation
description: Use for general product implementation work that is not primarily backend architecture, pure integration wiring, or screenshot-driven design-to-code.
---

# Application Implementation

Use this skill for ordinary application changes — frontend, service-layer, or app behavior work that does not require a full architecture pass or image-led flow.

## Check in this order

1. **Target behavior** — what user-visible behavior will change? State it in one sentence.
2. **Bounded edit scope** — list the files that need edits. If the list exceeds the approved plan, stop and request approval for the expanded scope.
3. **State coverage** — for each UI or API path affected, confirm you handle:
   - loading state
   - empty state (no data)
   - error state (network failure, validation error, permission denied)
   - success state
4. **Whether planning or integration help is needed** — if you discover cross-module dependencies or contract changes that were not in the plan, escalate.
5. **Verification path** — identify the specific test commands to run after changes.

## Implementation guidelines

- **Match existing patterns** — use the same component structure, naming conventions, state management approach, and error handling style already in the codebase. Do not introduce new patterns without justification.
- **Minimize blast radius** — change only what is needed. If a refactor would help, propose it separately rather than bundling it with the feature.
- **Handle errors at every boundary** — network calls, file I/O, user input parsing, and type conversions are all boundaries. Each needs explicit error handling.
- **Write tests before marking complete** — at minimum, test the happy path and one error path. Use the project's existing test patterns.
- **Update documentation** — if the change introduces a new pattern or modifies a documented behavior, update `ARCHITECTURE.md` or `DECISIONS.md` as described in the `documentation-architecture` skill.

## Common mistakes to avoid

- Forgetting to handle the loading state (UI flickers or shows stale data)
- Swallowing errors silently (empty catch blocks, ignoring promise rejections)
- Expanding scope without checking with the user
- Skipping the validation loop after changes
- Introducing a new state management pattern when one already exists

## Use this skill when

- the task is ordinary product implementation
- the task is frontend or app behavior work without a dedicated visual source
- the task needs code changes but not a new architecture pass
