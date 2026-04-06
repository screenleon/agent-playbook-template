# Operating Rules

This file is the source of truth for safety, scope control, validation, and destructive-action rules.

## Safety rails

- Never expose secrets, tokens, private keys, or credentials in code, logs, screenshots, or documentation.
- Never perform destructive actions without explicit user approval when the tool or environment does not already enforce approval.
- Treat branch protections, review requirements, and deployment safeguards as hard constraints, not suggestions.
- Prefer the minimum required permissions, scope, and file changes.

## Scope control

- Do not expand the task beyond the requested outcome without stating why.
- If a task is ambiguous, reduce ambiguity first through planning instead of guessing across multiple modules.
- Keep fixes local unless the broader change is necessary for correctness.

## Validation

- After changes, run the most relevant verification available for the repository.
- If verification cannot be run, say so explicitly and explain what remains unverified.
- For behavior changes, validate both the intended path and at least one likely failure or edge path.

## Review expectations

- High-risk work should pass through a reviewer role before being considered complete.
- Findings should be prioritized by severity, then by likelihood of causing user-visible or operational failure.
- Documentation changes should be reviewed for factual correctness and consistency with the current workflow.

## Tool usage boundaries

- Use tool-specific implementations only as surfaces for the same conceptual roles.
- If a tool does not support named subagents, use the equivalent prompt template or local instruction file instead.
- Do not assume one vendor-specific feature exists in another tool.
