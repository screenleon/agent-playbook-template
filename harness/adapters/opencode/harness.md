---
description: Bootstrap harness environment and display governance rules for this session
---

Run the following shell command to bootstrap the harness:

```bash
eval "$(bash harness/bootstrap.sh)"
```

After bootstrap, the following variables are available:

- `HARNESS_EXECUTION_MODE` — supervised | semi-auto | autonomous
- `HARNESS_BUDGET_PROFILE` — nano | minimal | standard | full
- `HARNESS_LAYER1_FILES` — space-separated list of Layer 1 docs to load
- `HARNESS_PACK_ID` — unique identifier for this session
- `HARNESS_TRACE_ID` — unique trace identifier

Load all files in `HARNESS_LAYER1_FILES` before reading task context.

## Gate rules

Before executing any always-dangerous operation, output:

```text
[HARNESS GATE] Awaiting approval for: <operation>
Reason: <why needed>
```

Always-dangerous operations (always require explicit user confirmation):

- `git push --force`, `git reset --hard`, amending published commits
- Deleting files or directories
- Dropping database tables or destructive migrations
- Modifying `.github/workflows/`, CI/CD pipelines, or deployment configs
- Publishing packages or pushing to `main`/`production` branches

## POST phase

After completing the task:

1. Emit a trace record (see `docs/agent-playbook.md` → step 14).
2. Run `bash harness/adapters/generic/post-invoke.sh`.
