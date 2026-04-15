# Example Profile: High-Security Mode

Use this profile for regulated or security-critical systems.

## Priorities

1. Security and compliance before velocity
2. Strict permission and approval controls
3. Maximum auditability and traceability

## Suggested configuration

```yaml
execution_mode: supervised

budget:
  profile: full

roles:
  enabled:
    - feature-planner
    - backend-architect
    - application-implementer
    - documentation-architect
    - risk-reviewer
    - critic
```

## Rules emphasis

- Enforce least-privilege everywhere.
- Require threat-model review for auth, permissions, and external integrations.
- Require test-first for all behavior changes, including medium-risk bug fixes.
- Require decision log entry for every security-relevant tradeoff.

## Recommended workflow

`feature-planner` → `critic` → `risk-reviewer` (plan assessment) → **user approval** → `application-implementer` or `backend-architect` → `risk-reviewer` (final review)
