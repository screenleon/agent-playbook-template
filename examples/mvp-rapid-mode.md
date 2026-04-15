# Example Profile: MVP / Rapid Mode

Use this profile for early-stage products prioritizing delivery speed.

## Priorities

1. Fast iteration
2. Tight scope and rapid feedback
3. Lightweight process with basic safety

## Suggested configuration

```yaml
execution_mode: semi-auto

budget:
  profile: standard

roles:
  enabled:
    - feature-planner
    - application-implementer
    - risk-reviewer
    - critic
  disabled:
    - backend-architect
    - ui-image-implementer
    - integration-engineer
    - documentation-architect
```

## Rules emphasis

- Keep changes small and reversible.
- Preserve mandatory validation loop, but prefer targeted tests first.
- Require architecture decisions only when boundaries or contracts change.
- Use concise summaries instead of verbose deliverables for Small tasks.

## Recommended workflow

Bounded Small/Medium changes: `application-implementer` → targeted validation → brief summary or `risk-reviewer` when the routed workflow requires it.
