# OpenCode Adapter

OpenCode supports project agents and custom commands. The harness provides a ready-to-copy command file.

## Native capabilities used

| OpenCode surface | Harness mapping |
|-----------------|----------------|
| `.opencode/commands/harness.md` | Bootstrap command — agents run it at session start |
| `.opencode/agents/` | Role definitions (copy from `.claude/agents/` if available) |
| `AGENTS.md` | Loaded natively by OpenCode as the entrypoint |

## Adoption (copy-based — no install script needed)

```bash
mkdir -p .opencode/commands
cp harness/adapters/opencode/harness.md .opencode/commands/harness.md
```

For role definitions, copy from `.claude/agents/` if you have Claude Code config:

```bash
mkdir -p .opencode/agents
cp .claude/agents/*.md .opencode/agents/
```

In an OpenCode session, use `/harness` to bootstrap the environment.

## Enforcement gap

OpenCode has no per-tool-call hook API. Gate checks in the command file are advisory.

Mitigation: use `execution_mode: supervised`.
