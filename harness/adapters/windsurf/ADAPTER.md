# Windsurf Adapter

Windsurf uses `.windsurfrules` (a single Markdown file at the repository root) for repository-scoped agent instructions. The harness provides a ready-to-copy template.

## Native capabilities used

| Windsurf surface | Harness mapping |
|-----------------|----------------|
| `.windsurfrules` | Bootstrap instructions + gate rules |
| Pre/post scripts | Generic adapter scripts (Windsurf has no hook API) |

## Adoption (copy-based — no install script needed)

```bash
cp harness/adapters/windsurf/harness-rules.md .windsurfrules
```

If `.windsurfrules` already exists, append instead:

```bash
cat harness/adapters/windsurf/harness-rules.md >> .windsurfrules
```

## POST phase

After each session, run:

```bash
bash harness/adapters/generic/post-invoke.sh
```

Or wire it as a CI step.

## Enforcement gap

Windsurf has no per-tool-call hook API. Gate checks in `.windsurfrules` are advisory — the agent is instructed to self-check before dangerous operations but cannot be programmatically blocked.

Mitigation: use `execution_mode: supervised`.
