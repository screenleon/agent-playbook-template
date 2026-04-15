---
name: prompt-cache-optimization
description: Use to maximize prompt cache hit rates across LLM providers by enforcing a stable instruction loading order and file size discipline.
---

# Prompt Cache Optimization

Use this skill to reduce API costs and latency by maximizing prompt cache hits. The techniques here are **provider-agnostic** — they work with any LLM that uses prefix-based prompt caching (Anthropic, OpenAI, Google, local inference engines like vLLM/SGLang). The key requirement: **the beginning of the prompt must be identical byte-for-byte across requests** — instruction files must load in a consistent, deterministic order.

## Four-layer loading order

Instruction content is classified into four layers by **change frequency**, loaded from most stable to most volatile:

```text
Layer 1 — Static rules (rarely change)
  ├── docs/operating-rules.md
  └── docs/agent-playbook.md

Layer 2 — Stable skills (content stable; subset varies by task type)
  ├── AGENTS.md
  └── skills/*/SKILL.md (selected by demand-triage)

Layer 3 — Semi-stable project state (changes weekly to monthly)
  ├── DECISIONS.md
  └── ARCHITECTURE.md (if present)

Layer 4 — Volatile context (changes every request)
  ├── Session memory / context anchors
  ├── User query
  └── Current file content / code snippets
```

### Rules

1. **Always load layers in order**: Layer 1 → Layer 2 → Layer 3 → Layer 4. Never reorder.
2. **Layer 1 content must be identical across all requests** in a session. Do not inject per-request content into Layer 1.
3. **Layer 2 skills must be loaded in a deterministic order** for the same task type (see Skill loading order below).
4. **Layer 3 content should be loaded after Layer 2** so that edits to `DECISIONS.md` do not invalidate the Layer 1+2 cache prefix.
5. **Layer 4 is always last**. This is the only layer expected to differ between requests.

### Cache boundary visualization

```text
┌─────────────────────────────────────────────┐
│  Layer 1: Static rules                      │  ← Cached across ALL requests
│  Layer 2: Stable skills                     │  ← Cached across same-type tasks
├─────────────────────────────────────────────┤
│  Layer 3: DECISIONS.md, ARCHITECTURE.md     │  ← Cached until project state changes
├─────────────────────────────────────────────┤
│  Layer 4: Session context, user query       │  ← Never cached (unique per request)
└─────────────────────────────────────────────┘
```

## Skill loading order

When multiple skills are loaded for a task, use **alphabetical order by skill directory name** within the same layer. This ensures the same set of skills always produces the same prefix.

### Canonical skill sets by task type

| Task type | Skills loaded (in order) |
|-----------|-------------------------|
| Small task | `demand-triage`, `repo-exploration` |
| Medium frontend | `application-implementation`, `demand-triage`, `repo-exploration`, `test-and-fix-loop` |
| Medium backend | `backend-change-planning`, `demand-triage`, `repo-exploration`, `test-and-fix-loop` |
| Large feature | `demand-triage`, `feature-planning`, `repo-exploration`, `test-and-fix-loop` |
| Design-to-code | `demand-triage`, `design-to-code`, `repo-exploration`, `test-and-fix-loop` |
| Documentation | `demand-triage`, `documentation-architecture`, `repo-exploration` |
| Error recovery | `error-recovery` (added on-demand; appended after existing skills) |
| Memory maintenance | `memory-and-state` (added on-demand; appended after existing skills) |

On-demand skills (`error-recovery`, `memory-and-state`, `prompt-cache-optimization`) are **appended after** the canonical set when needed. They never change the order of the canonical set.

## File size discipline

Large instruction files push volatile content further from the prefix boundary, increasing the cached portion. But excessively large files waste tokens when their content is not relevant.

### Guidelines

| Metric | Target | Action if exceeded |
|--------|--------|--------------------|
| Single instruction file | ≤ 8 KB (~2000–3000 tokens) | Split into focused files; load only what the task needs |
| Layer 1 total | ≤ 20 KB | Review for redundancy; move examples to templates |
| Layer 2 per-task total | ≤ 15 KB | Ensure demand-triage selects only relevant skills |
| DECISIONS.md (Layer 3) | ≤ 30 KB | Trigger archive per `memory-and-state` skill |

### Interaction with memory lifecycle

The `memory-and-state` skill's archive rules (30 KB / 50 entries threshold for `DECISIONS.md`) directly support cache optimization by keeping Layer 3 compact. When Layer 3 grows, it pushes Layer 4 further out and reduces the effective cache window. Treat memory lifecycle thresholds as cache-relevant, not just memory-relevant.

## Provider-specific notes

| Provider | Cache mechanism | Minimum prefix | TTL | Notes |
|----------|----------------|---------------|-----|-------|
| Anthropic (Claude) | Automatic prefix cache | ~1024 tokens | ~5 min | Also supports explicit cache_control breakpoints via API |
| OpenAI (GPT-4o, o1, etc.) | Automatic prefix cache | ~1024 tokens (128-token aligned) | ~5–10 min | Discounts cached input tokens automatically |
| Google (Gemini) | Context Caching API | Configurable | Configurable | Requires explicit API call to create cached content |
| vLLM / SGLang | RadixAttention / prefix cache | Varies | Session-scoped | Automatic; benefits from stable system prompt |

### Tool-specific adaptation

| Tool | How to apply loading order |
|------|---------------------------|
| Claude Code | Already has built-in optimization; loading order provides additional prefix stability |
| VS Code Copilot | `.github/copilot-instructions.md` is auto-injected (Layer 1); skills are read by agent in declared order (Layer 2) |
| Custom API calls | Place Layer 1–2 in `system` message; Layer 3 at start of `user` message; Layer 4 as the rest of `user` message |
| Claude API with cache_control | Set cache breakpoints at Layer 1–2 boundary and Layer 2–3 boundary |

## Tool definition stability

Tool/function schemas are part of the prompt and count toward the prefix. Unstable tool definitions cause cache misses just like unstable instructions.

### Rules

1. **Fixed tool set per task type** — load only the tools required for the current task type. Do not inject every available tool into every request.
2. **Deterministic order** — always list tool definitions in the same order (alphabetical by tool name). Different orderings produce different prefixes.
3. **Stable schemas** — do not regenerate tool JSON schemas per request. Use a versioned schema definition and include only the version identifier when the schema has not changed.
4. **Place tool definitions in Layer 1 or Layer 2** — tool schemas are static content; they belong before volatile context.

### Tool registry pattern (for custom API callers)

When building custom agent orchestration on top of LLM APIs, avoid sending full JSON schema on every request. Use a two-part model: a server-side registry that stores the full schema, and a lightweight per-request payload that references it by name and hash.

Registry (stored server-side or in project config):

```yaml
tools:
  create_order_v2:
    schema_hash: "abc123"
    schema: { ... full JSON schema ... }
```

Per-request payload (lightweight — references the registered schema by name and version):

```json
{
  "tools": ["create_order_v2"],
  "tool_schema_version": "abc123"
}
```

If the LLM provider requires full schemas in each request (most do today), ensure schemas are loaded from a stable source in a deterministic order so the prefix remains consistent. The registry pattern becomes directly useful when providers support schema references or when using self-hosted inference.

### Tool subset by task type

| Task type | Typical tools needed |
|-----------|---------------------|
| Code implementation | file read/write, terminal, search, lint |
| Planning / review | file read, search, memory |
| Documentation | file read/write, search |

Avoid loading code-modification tools for read-only review tasks. This reduces prompt size and keeps the prefix shorter.

## Prompt budget configuration

Adopting projects can declare a `prompt-budget.yml` at the repo root to control which skills and roles load per request. This makes token usage visible and auditable.

### How agents use prompt-budget.yml

1. **Read `budget.profile`** — if set, use the named profile (`nano`, `minimal`, `standard`, `full`) as the default configuration. If not set, default to `standard`.
2. **Apply explicit overrides** — any `skills.*` or `roles.*` entries in the file override the profile defaults.
3. **During skill loading** — check `skills.disabled`; skip those skills entirely.
4. **During role selection** — check `roles.disabled`; do not route to those roles.
5. **During demand-triage** — if the loaded skill set would exceed `budget.layer2_max_tokens`, load only `skills.always_load` and defer on-demand skills.
6. **During memory maintenance** — use `trimming.*` thresholds instead of defaults from `memory-and-state` skill.

### Budget profile loading behavior

| Profile | Layer 2 ceiling | Skills loaded | Behavior differences |
|---------|-----------------|---------------|---------------------|
| `nano` | 0 tokens | 0 (all behaviors native) | Single-file Small tasks only. Layer 1 = `docs/rules-nano.md` (~630 tokens). No skill files loaded. Agent escalates immediately for multi-file or complex tasks. |
| `minimal` | ≤ 4,000 tokens | 2 (demand-triage, repo-exploration) | Agent uses native tool capabilities for testing, error handling, and memory. No structured traces. Small tasks only. |
| `standard` | ≤ 8,000 tokens | 5 (all Always-tier) | Conditional skills activate by trigger. On-demand domain skills require explicit opt-in. |
| `full` | ≤ 15,000 tokens | 5 + all applicable Conditional + On-demand | No restrictions. Full observability, self-reflection, and planning. |

When `budget.profile: minimal`, agents should:
- Run tests directly using tool-native test execution instead of loading `test-and-fix-loop`.
- Use built-in retry logic instead of loading `error-recovery`.
- Read `DECISIONS.md` directly instead of loading `memory-and-state`.
- Skip self-reflection, observability, and planning skills entirely.

See `docs/agent-playbook.md` → Budget profiles for the complete specification.

### Profile-aware Layer 1 loading

The Layer 1 content varies by budget profile to respect token targets:

| Profile | Layer 1 content | Est. tokens |
|---------|----------------|------------|
| `nano` | `docs/rules-nano.md` only | ~630 |
| `minimal` | `docs/rules-quickstart.md` only | ~1,200 |
| `standard` | `docs/rules-quickstart.md` → expand to full docs as needed | ~4,000–5,000 |
| `full` | Full `docs/operating-rules.md` + `docs/agent-playbook.md` | ~18,350 |

When `budget.profile: minimal`:

- Layer 1 consists solely of `docs/rules-quickstart.md` (enhanced with constitutional principles, checkpoint outcomes, and minimal-profile role definitions).
- Do NOT load `docs/operating-rules.md` or `docs/agent-playbook.md` unless a specific section is needed (deferred loading via "When to open full docs" in rules-quickstart.md).
- This brings Layer 1 from ~18,350 tokens to ~1,200 tokens — a 15x reduction.

When `budget.profile: standard` or unset:

- Load `docs/rules-quickstart.md` first, then expand into the full source docs for task-specific detail.

When `budget.profile: full`:

- Load the complete `docs/operating-rules.md` and `docs/agent-playbook.md` immediately.

If `prompt-budget.yml` does not exist, use the `standard` profile defaults with the full skill sets defined in the Canonical skill sets table above.

### Reference schema

```yaml
# prompt-budget.yml
budget:
  profile: standard
  layer1_target_tokens: 3000    # Static rules target
  layer2_max_tokens: 6000       # Skills per request
  layer3_max_tokens: 3000       # DECISIONS.md + ARCHITECTURE.md

roles:
  enabled: [feature-planner, application-implementer, risk-reviewer, critic]
  disabled: [backend-architect, ui-image-implementer, integration-engineer, documentation-architect]

skills:
  always_load: [demand-triage, repo-exploration, test-and-fix-loop, error-recovery, memory-and-state]
  on_demand: [prompt-cache-optimization]
  disabled: [design-to-code, documentation-architecture]

trimming:
  decisions_archive_threshold_kb: 30
  decisions_archive_threshold_entries: 50
  session_memory_max_files: 10
```

See `docs/adoption-guide.md` → Prompt budget trimming for step-by-step adoption guidance and impact estimates.

## Anti-patterns

- **Embedding volatile content in system prompt** — session state, timestamps, or user-specific data in the system message invalidate the entire prefix cache. Keep these in Layer 4.
- **Randomizing skill load order** — loading skills in different orders across requests of the same type creates different prefixes, causing cache misses.
- **Inlining DECISIONS.md into Layer 1** — project state changes frequently; mixing it into static rules invalidates the most stable cache layer.
- **Skipping demand-triage** — without triage, skill selection varies unpredictably, reducing prefix consistency across similar tasks.
- **Letting DECISIONS.md grow unbounded** — a 50 KB decision log in Layer 3 wastes tokens and pushes the cache boundary; use archive rules from `memory-and-state`.

### Cache-breaking anti-patterns

Avoid these behaviors during an active task or conversation:

- **Rebuilding earlier prompt layers mid-task** — do not rewrite or reshuffle Layer 1-3 content unless the task genuinely changed scope.
- **Changing tool definitions or tool subsets every turn** — unstable tool availability changes the prefix and reduces cache reuse.
- **Reloading memory files on every request** — keep stable project memory in Layer 3 and refresh it only when the underlying source changed or the task crossed a meaningful boundary.
- **Promoting temporary notes into stable layers** — scratchpad state, timestamps, one-off observations, and partial outputs belong in Layer 4 only.

When task scope changes enough to require a different skill set, acknowledge that the cache boundary will move and keep the new loading order deterministic from that point onward.

## Conformance self-check

Before completing a task where this skill applies, verify:

- [ ] Layer 1 content is identical to what other recent requests used (no per-request injection)
- [ ] Skills were loaded in alphabetical order within Layer 2
- [ ] DECISIONS.md and project state files are in Layer 3, not Layer 1 or 2
- [ ] Volatile content (user query, current file, session notes) is in Layer 4 only
- [ ] Always-loaded instruction files stay within the 8 KB guideline; justified exceptions are limited to on-demand skills
- [ ] DECISIONS.md is within the 30 KB threshold (or archive has been triggered)
