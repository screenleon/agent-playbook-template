# Budget Profile Examples

Complete example configurations for each budget profile.
Copy the relevant block into `prompt-budget.yml` (at the repo root), uncommenting as needed.

See `skills/prompt-cache-optimization/SKILL.md` → Profile-aware Layer 1 loading for how agents use these profiles.

Profiles from tightest to most capable: `nano` → `minimal` → `standard` → `full`.

---

## Nano profile (< 3,000 total tokens)

Best for: extreme token constraints, pay-per-token APIs with very tight limits,
simple single-file fixes where only native tool capabilities are available.
Estimated total execution: ~2,000–2,500 tokens (framework + task files).

Layer 1: agents load only `docs/rules-nano.md` (~630 tokens). No skills are loaded.
No demand-triage, no repo-exploration — agent uses native tool capabilities only.
**Suitable for single-file Small tasks only.** For anything multi-file or risky, escalate.

```yaml
budget:
  profile: nano
  layer1_target_tokens: 700
  layer2_max_tokens: 0
  layer3_max_tokens: 500

roles:
  enabled:
    - application-implementer
  disabled:
    - feature-planner
    - backend-architect
    - ui-image-implementer
    - integration-engineer
    - documentation-architect
    - risk-reviewer
    - critic

skills:
  always_load: []
  on_demand: []
  disabled:
    - demand-triage
    - repo-exploration
    - test-and-fix-loop
    - error-recovery
    - memory-and-state
    - self-reflection
    - observability
    - feature-planning
    - backend-change-planning
    - design-to-code
    - documentation-architecture
    - prompt-cache-optimization
    - on-project-start
    - mcp-validation
    - skill-creator
    - application-implementation
```

---

## Minimal profile (< 16K total context)

Best for: solo devs with tight token limits, Small tasks only,
pay-per-token APIs, or constrained model context windows.
Estimated Layer 2 cost: ~2,000–3,000 tokens.

Layer 1 note: at minimal profile, agents load only `docs/rules-quickstart.md`
as Layer 1 (~1,300 tokens), skipping the full `operating-rules.md` and
`agent-playbook.md`. See `docs/rules-quickstart.md` → Loading rule.

```yaml
budget:
  profile: minimal
  layer1_target_tokens: 3000
  layer2_max_tokens: 4000
  layer3_max_tokens: 2000

roles:
  enabled:
    - application-implementer
    - critic
  disabled:
    - feature-planner
    - backend-architect
    - ui-image-implementer
    - integration-engineer
    - documentation-architect
    - risk-reviewer

skills:
  always_load:
    - demand-triage
    - repo-exploration
  on_demand: []
  disabled:
    - test-and-fix-loop          # agent runs tests natively
    - error-recovery             # agent uses built-in retry
    - memory-and-state           # agent reads DECISIONS.md directly
    - self-reflection            # skipped
    - observability              # skipped
    - feature-planning           # no planning phase
    - backend-change-planning    # no planning phase
    - design-to-code             # not needed
    - documentation-architecture # not needed
    - prompt-cache-optimization  # not needed at minimal scale
    - on-project-start           # run once manually, then disable
    - mcp-validation             # not needed
    - skill-creator              # not needed at minimal scale
    - application-implementation # not needed at minimal scale
```

---

## Standard profile (default)

Best for: typical team usage, Small/Medium tasks,
moderate token budgets (16K–32K context).
Estimated Layer 2 cost: ~7,000–10,000 tokens.

```yaml
budget:
  profile: standard
  layer1_target_tokens: 4000
  layer2_max_tokens: 8000
  layer3_max_tokens: 3000

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

skills:
  always_load:
    - demand-triage
    - repo-exploration
    - test-and-fix-loop
    - error-recovery
    - memory-and-state
  on_demand:
    - prompt-cache-optimization
  disabled:
    - design-to-code
    - documentation-architecture
```

---

## Full profile

Best for: large teams, Large tasks, high-risk projects,
generous budgets (32K+ context).
Estimated Layer 2 cost: ~12,000–18,000 tokens.

```yaml
budget:
  profile: full
  layer1_target_tokens: 4000
  layer2_max_tokens: 15000
  layer3_max_tokens: 3000

roles:
  enabled:
    - feature-planner
    - backend-architect
    - application-implementer
    - ui-image-implementer
    - integration-engineer
    - documentation-architect
    - risk-reviewer
    - critic
  disabled: []

skills:
  always_load:
    - demand-triage
    - repo-exploration
    - test-and-fix-loop
    - error-recovery
    - memory-and-state
  on_demand:
    - self-reflection
    - observability
    - prompt-cache-optimization
    - feature-planning
    - backend-change-planning
    - application-implementation
    - design-to-code
    - documentation-architecture
    - on-project-start
    - mcp-validation
    - skill-creator
  disabled: []
```
