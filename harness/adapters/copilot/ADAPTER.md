# GitHub Copilot Adapter

GitHub Copilot has no runtime hook mechanism. Governance is delivered via instruction injection and CI enforcement.

## Native capabilities used

| Copilot surface | Harness mapping |
|----------------|----------------|
| `.github/copilot-instructions.md` | Governance block injected as standing agent instructions |
| GitHub Actions | POST phase: trace validation + decision capture as a CI step |
| `.github/prompts/` | Context pack delivered as a prompt file (optional) |

## Adoption (append-based — no install script needed)

1. Copy the contents of `governance-block.md` and append it to `.github/copilot-instructions.md`:

```bash
cat harness/adapters/copilot/governance-block.md >> .github/copilot-instructions.md
```

2. Add a POST validation step to your CI workflow:

```yaml
- name: Harness post-validation
  run: bash harness/adapters/generic/post-invoke.sh
```

3. (Optional) Copy `governance-block.md` to `.github/prompts/harness-governance.prompt.md` if you want to load it selectively per task.

## Enforcement gap

Copilot cannot intercept individual tool calls at runtime. Gate checks are advisory — the governance block instructs the agent to self-report, but cannot programmatically block tool calls.

Mitigation: use `execution_mode: supervised` so agents check in before destructive ops.
