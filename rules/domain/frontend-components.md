# Domain Template: Frontend Component Rules

Use this template for frontend component constraints reusable across repositories.

## Rule entries

Repeat this block for each rule.

```markdown
### Rule: <RULE_ID>
- Owner layer: Domain
- Domain: frontend-components
- Stability: <core | behavior | experimental>
- Status: active
- Scope: <module or surface>
- Directive: <clear non-negotiable rule>
- Rationale: <why>
- Conflict handling: <what overrides this rule or when to escalate>
- Example: <positive example>
- Non-example: <what this rule forbids or does not cover>
- Supersedes: <RULE_ID or N/A>
- Superseded by: <RULE_ID or N/A>
```

## Starter examples

### Rule: UI-001

- Owner layer: Domain
- Domain: frontend-components
- Stability: behavior
- Status: active
- Scope: shared UI components
- Directive: Shared components must be stateless unless local UI state is required.
- Rationale: Predictable rendering and easier testing.
- Conflict handling: Local UI state is allowed for interaction state that cannot reasonably be owned by a parent component.
- Example: A shared button receives label, disabled, and loading state through props.
- Non-example: A shared card component silently fetches its own data and owns app-level navigation state.
- Supersedes: N/A
- Superseded by: N/A

### Rule: UI-002

- Owner layer: Domain
- Domain: frontend-components
- Stability: behavior
- Status: active
- Scope: form interactions
- Directive: All form components must expose loading, error, and disabled states.
- Rationale: Consistent UX and accessibility.
- Conflict handling: Project rules may define the exact visual treatment, but cannot omit states required for accessible feedback.
- Example: A submit button can show loading, disabled, and field-level error states.
- Non-example: A form remains clickable during submission and only reports failures through console logs.
- Supersedes: N/A
- Superseded by: N/A
