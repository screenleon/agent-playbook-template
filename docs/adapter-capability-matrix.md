# Adapter Capability Matrix

Use this table to choose the right adapter for your runtime. Each column covers a
capability area that affects how governance hooks, model tier routing, and context
delivery work in practice.

For full adoption steps, see `harness/adapters/<name>/ADAPTER.md`.

---

## Feature comparison

| Feature | claude-code | copilot | cursor | opencode | windsurf | generic |
|---------|:-----------:|:-------:|:------:|:--------:|:--------:|:-------:|
| **Native hook API** (`PreToolUse`/`Stop`) | ✅ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **Gate-check enforcement** (hard block) | ✅ | advisory | advisory | advisory | advisory | advisory |
| **Trace validation on session end** | ✅ (Stop hook) | CI only | CI only | CI only | CI only | CI only |
| **Decision capture on file write** | ✅ (PostToolUse) | CI only | CI only | CI only | CI only | manual |
| **Native subagent / role isolation** | ✅ (`.claude/agents/`) | ✗ | ✗ | via `.opencode/agents/` | ✗ | ✗ |
| **Repository instruction injection** | `.claude/AGENTS.md` | `.github/copilot-instructions.md` | `.cursor/rules/*.mdc` | `AGENTS.md` native | `.windsurfrules` | prompt/env |
| **Model routing / provider control** | via API config | via model picker | via model picker | via config | via config | env vars |
| **Context pack delivery** | via task prompt | `.github/prompts/` | `.cursor/rules/` | `/harness` command | rule injection | pre-invoke script |
| **CI post-validation** | native + CI | CI required | CI required | CI required | CI required | CI required |
| **`failure-family-detect.sh` usable** | ✅ (PostToolUse) | ✅ (CI step) | ✅ (CI step) | ✅ (CI step) | ✅ (CI step) | ✅ (manual) |
| **`validate-prompt-budget.py` usable** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Notes per adapter

### claude-code
Full harness support. Uses `PreToolUse` / `PostToolUse` / `Stop` hooks from
`harness/adapters/claude-code/settings.hooks.json`. The only adapter where gate
checks are **programmatic** (non-advisory). Preferred when you need strict
enforcement of destructive-action gates.

**model routing**: set model via Claude API config or `CLAUDE_MODEL` env var; map abstract
tiers in `prompt-budget.local.yml` → `provider_model_map.claude.*`.

### copilot
No runtime hook API. Governance delivered via instruction injection in
`.github/copilot-instructions.md` and enforced via CI workflows (`agent-review.yml`,
`rule-governance.yml`). Gate checks are self-reported only — use
`execution_mode: supervised` to maximize safety.

**model routing**: model selection is controlled by the Copilot model picker in the
IDE or via the API `model` parameter. Map abstract tiers in `prompt-budget.local.yml`
→ `provider_model_map.copilot.*`.

### cursor
No hook API. Instructions injected via `.cursor/rules/harness.mdc` with `alwaysApply: true`.
POST-phase validation runs as a CI step or manual `post-invoke.sh`. Gate checks are advisory.

**model routing**: select model via Cursor settings panel; map abstract tiers in
`prompt-budget.local.yml` → `provider_model_map.cursor.*` or set via Cursor API.

### opencode
AGENTS.md loaded natively. Supports `.opencode/agents/` for role definitions (copy from
`.claude/agents/`). No hook API; `/harness` command bootstraps at session start.

**model routing**: set via OpenCode config; map tiers in `prompt-budget.local.yml`.

### windsurf
Instructions injected via `.windsurfrules`. No hook API. POST phase is manual or CI.
Gate checks are advisory.

**model routing**: set via Windsurf model selector; map tiers in `prompt-budget.local.yml`.

### generic
Fallback for any unsupported tool. Replaces hooks with explicit `pre-invoke.sh` /
`post-invoke.sh` wrapper scripts. Works with any CLI agent tool. Requires the most
manual discipline — best paired with `execution_mode: supervised`.

**model routing**: pass via environment variables to the CLI invocation; map tiers
in `prompt-budget.local.yml` → `provider_model_map.generic_api.*`.

---

## Choosing an adapter

```
Does your runtime support PreToolUse/Stop hooks?
   └─ Yes → claude-code
   └─ No
      ├─ Using GitHub Copilot? → copilot
      ├─ Using Cursor?         → cursor
      ├─ Using OpenCode?       → opencode
      ├─ Using Windsurf?       → windsurf
      └─ Other / CLI agent     → generic
```

For strict gate enforcement, prefer **claude-code**. For teams already on a specific
IDE, pick the matching adapter and enforce governance through CI.

---

## Enforcement gap summary

All non-claude-code adapters share the same fundamental gap: there is no runtime
mechanism to **block** tool calls programmatically. The harness can instruct the agent
to self-check, but cannot intercept if the agent ignores the instruction.

Mitigation strategies ranked by reliability:

1. `execution_mode: supervised` — human approval gate before destructive operations
2. CI `agent-review.yml` — catches violations post-session
3. `execution_mode: semi-auto` + `halt_on_destructive_actions: true` — for most team use
