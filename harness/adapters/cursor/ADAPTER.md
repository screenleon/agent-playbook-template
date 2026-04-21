# Cursor Adapter

Cursor uses `.cursor/rules/` (MDC format) for repository-scoped agent instructions. The harness rule file is a ready-to-copy template.

## Native capabilities used

| Cursor surface | Harness mapping |
|----------------|----------------|
| `.cursor/rules/harness.mdc` | Bootstrap instructions + gate rules as an always-applied rule |
| Pre/post scripts | Generic adapter scripts (Cursor has no hook API) |

## Adoption (copy-based — no install script needed)

```bash
mkdir -p .cursor/rules
cp harness/adapters/cursor/harness.mdc .cursor/rules/harness.mdc
```

That's it. Cursor auto-loads all `.mdc` files in `.cursor/rules/` with `alwaysApply: true`.

## POST phase

After each session, run:

```bash
bash harness/adapters/generic/post-invoke.sh
```

Or wire it as a CI step.

## Enforcement gap

Cursor has no per-tool-call hook API. Gate checks in `harness.mdc` are advisory — the agent is instructed to self-check before dangerous operations but cannot be programmatically blocked.

Mitigation: use `execution_mode: supervised`.
