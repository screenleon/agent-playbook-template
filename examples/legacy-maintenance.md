# Example Profile: Legacy Maintenance

Use this profile for older stacks where stability and compatibility are more important than modernization.

## Priorities

1. Minimize regression risk
2. Respect existing conventions
3. Constrain change scope aggressively

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

skills:
  disabled:
    - design-to-code
    - documentation-architecture
```

## Rules emphasis

- Follow existing codebase practice by default.
- Do not introduce new frameworks or architectural patterns without explicit approval.
- Require contradiction checks against both `DECISIONS.md` and `DECISIONS_ARCHIVE.md` for legacy areas.
- Encourage characterization tests before touching fragile modules.

## Recommended workflow

Bounded maintenance change: `application-implementer` → targeted validation → `risk-reviewer` when risk or regressions matter.

For legacy modules, use `memory-and-state` retrieval to inspect both `DECISIONS.md` and `DECISIONS_ARCHIVE.md` before changing behavior.
