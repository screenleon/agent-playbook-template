<!-- harness-adapter:copilot -->
## Harness governance

Before starting any task:

1. Run `eval "$(bash harness/bootstrap.sh)"` to load execution mode, budget profile, and layer-1 files into your session environment.
2. Load the files listed in `HARNESS_LAYER1_FILES` before reading task context.
3. If `HARNESS_EXECUTION_MODE` is `supervised`, stop and confirm with the user before any always-dangerous operation.

Always-dangerous operations — output `[HARNESS GATE] Awaiting approval for: <operation>` and wait for explicit user confirmation before executing:

- `git push --force`, `git reset --hard`, amending published commits, `git branch -D`
- Deleting files or directories
- Dropping database tables or running destructive migrations
- Modifying `.github/workflows/`, CI/CD pipelines, or deployment configs
- Publishing packages or pushing to `main`/`production` branches

After completing any task:

4. Emit a trace record per `docs/agent-playbook.md` → Mandatory steps (step 14).
5. Run `bash harness/adapters/generic/post-invoke.sh` to validate trace and capture decisions.
