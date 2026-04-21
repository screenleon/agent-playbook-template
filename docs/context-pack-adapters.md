# Context Pack Adapters

This document defines how to adapt one canonical context pack into different agent tools without turning tool-specific session state into the source of truth.

Related assets:

- `docs/schemas/context-pack.schema.json`
- `docs/agent-templates.md`
- `docs/adoption-guide.md`
- `docs/operating-rules.md`
- `docs/agent-playbook.md`

## Why this exists

The template already standardizes repository rules, role routing, and handoff artifacts. What varies by tool is the transport surface:

- some tools support repository rules
- some support subagents
- some support only one prompt at a time
- some compact sessions aggressively
- some wrap execution inside a task manager such as a daemon or issue queue

The context pack is the portable contract between those surfaces.

## Adapter principles

1. Canonical repository files remain authoritative.
2. The adapter translates context; it does not redefine project rules.
3. Role belongs in the strongest stable instruction surface the tool offers.
4. Intent mode belongs in the lightest task-scoped surface the tool offers.
5. Runtime summaries are useful for continuity, but they do not replace `DECISIONS.md` or other tracked docs.
6. Cross-role or cross-tool transitions should carry `pack_id`, `trace_id`, and any handoff reference forward.
7. If model selection is adapter-controlled, keep canonical files vendor-neutral and map only abstract model tiers to concrete provider/model IDs at the adapter or runtime layer.

## Translation layers

Every adapter should preserve these layers in order:

1. Canonical repository context
2. Context pack
3. Tool-specific wrapper
4. Runtime session state

Do not invert that order. If the runtime session becomes the only place a rule exists, the system will drift.

## Minimum adapter behavior

Every adapter should:

1. Validate the pack against `docs/schemas/context-pack.schema.json`.
2. Load or reference canonical files before task-scoped text.
3. Place `role` in the stable instruction surface when the tool supports it.
4. Place `intent_mode`, `approved_scope`, and `expected_output` in the task-scoped payload.
5. Preserve `source_marker`, `trace_id`, and `pack_id` in logs, issue metadata, or emitted artifacts.
6. Return a structured result or a human-readable summary that can be converted into a handoff artifact.
7. Treat session compaction output as runtime residue only.

If a project uses `prompt-budget.yml` → `model_routing`, adapters should map abstract tiers such as `fast`, `balanced`, and `deep` to concrete provider/model IDs outside canonical docs. When routing metadata must cross tools, carry the abstract tier only unless a runtime-specific debugging flow explicitly requires more detail.

### Recommended runtime rule: `repeated_failed_fix_loop`

Treat `repeated_failed_fix_loop` as satisfied only when **all** of the following are true:

1. The runtime has already used the current tier for at least `max_attempts_at_current_tier` repair attempts on the **same role, same task objective, and same dominant failure family**.
2. Each attempt ended in failed validation, an unresolved execution error, or a reverted/no-op outcome that did not clear the task.
3. The attempts did not materially reduce the problem. Examples:
  - the same dominant test or lint failure still remains
  - the same exception class or error signature still remains
  - the root cause is still unknown after the retries
4. The failure is not better explained by an external blocker such as missing credentials, unavailable infrastructure, bad fixture data, or a human approval checkpoint.
5. The task is not covered by `never_escalate_for`.

Recommended interpretation:

- Count attempts only when the runtime actually tried to repair the task at the current tier.
- Group failures by dominant family, not by exact text. Minor line-number drift or wording changes should still count as the same failure family.
- Reset the counter when the dominant failure family changes, the task objective changes, the role changes, or a human provides new information that changes the diagnosis.
- Do not wait for the global stuck-escalation threshold. `repeated_failed_fix_loop` is an earlier signal for tier escalation inside the same runtime, while the 3-failure stuck rule remains the stop condition for the overall task.

Practical default:

- Attempt 1 at `balanced`: fix and validate.
- Attempt 2 at `balanced`: fix and validate again.
- If the same dominant failure family persists with no meaningful reduction, mark `repeated_failed_fix_loop` true and retry at `deep`.
- If the task still cannot converge after the broader stuck-escalation limit, stop per the source-of-truth rules.

## Suggested adapter output contract

When a tool cannot emit a structured JSON result, its human-readable summary should still capture:

- `pack_id`
- `trace_id`
- role and intent mode
- changed files or touched modules
- validation status
- open risks
- decision deltas

This keeps later handoff generation deterministic.

## Tool mapping reference

| Tool family | Stable role surface | Task-scoped surface | Isolation pattern | Adapter notes |
|-------------|---------------------|---------------------|-------------------|---------------|
| Claude Code | `.claude/agents/*.md` | direct task prompt or handoff artifact | separate subagent or fresh invocation per role | Map `role` to project subagent. Carry `intent_mode` in the request body or handoff, not in a permanent agent definition. |
| GitHub Copilot | `.github/copilot-instructions.md` | prompt files or chat preamble | fresh chat or explicit handoff block for role changes | Best when the adapter keeps repository instructions short and places pack fields near the top of the task prompt. |
| Cursor / Windsurf | rules files | inline task preamble | same chat for same-role mode changes; new chat for role changes | Useful when no native subagents exist. The adapter must restate mode and scope explicitly before edits begin. |
| Codex CLI | `AGENTS.md` plus repo docs | user prompt prefix | new run or explicit handoff artifact for role changes | Prefer the context pack as a compact preamble rather than replaying raw transcript history. |
| OpenCode | `AGENTS.md`, project config, project agents | custom command body, prompt text, or `@agent` invocation | primary agent for main loop, subagent or new session for isolated work | Map `role` to a project agent when available. Map `intent_mode` to the command preamble. Auto-compact summaries are runtime-only and should not replace tracked docs. |
| Multica / managed-agent control plane | agent profile, skill library, issue template | issue body, task payload, or run dispatch payload | one issue or queued run per pack; preserve trace metadata across retries | Use the pack as the execution payload handed to the worker runtime. The task manager should point back to canonical repo files instead of storing unique rules only inside the issue. |
| Custom OpenAI API | selected system prompt variant | request metadata or top-of-user-message tags | new call chain per role when isolation matters | Best for orchestration services that need a uniform pack-to-request transformation. |

## OpenCode-specific guidance

OpenCode deserves explicit guidance because it offers both project rules and agent/command abstractions.

Recommended mapping:

- keep durable project guidance in `AGENTS.md` and adjacent docs
- create project-specific agents only for durable role behavior
- place `intent_mode` and `approved_scope` in the command body or per-task preamble
- treat `.opencode/commands/*.md` as derived assets, not canonical rules
- keep auto-compact and session-summary outputs in runtime storage only

If OpenCode custom commands inject shell output or files, the adapter should do so only from paths already allowed by `approved_scope`.

## Multica-specific guidance

Managed-agent tools add orchestration, assignment, and queueing, but they should not become the sole memory layer.

Recommended mapping:

- pack `role`, `intent_mode`, and `objective` into the task payload
- keep stable team-wide skills aligned with canonical repo docs
- attach `trace_id` and `pack_id` to the issue, run, or queue item
- keep retries idempotent at the queue layer rather than rewriting the pack
- record final summaries back into durable project artifacts only when they represent real rule or decision changes

This keeps orchestration state and repository knowledge separate.

## Example pack

```json
{
  "schema_version": "1.0.0",
  "pack_id": "ctx_2026_04_17_001",
  "generated_at": "2026-04-17T09:30:00Z",
  "objective": "Review the current API response shape and propose the minimal contract change.",
  "role": "application-implementer",
  "intent_mode": "analyze",
  "task_scale": "Small",
  "execution_mode": "semi-auto",
  "budget_profile": "standard",
  "approved_scope": {
    "summary": "Inspect response-shape code paths and targeted tests only.",
    "allowed_paths": [
      "src/api/",
      "src/tests/"
    ],
    "blocked_paths": [
      "db/migrations/"
    ],
    "non_goals": [
      "No schema changes",
      "No auth changes"
    ],
    "acceptance_criteria": [
      "Existing endpoint behavior is explained",
      "Minimal change set is identified",
      "Validation path is stated"
    ]
  },
  "constraints": [
    "Follow AGENTS.md",
    "Do not expand scope without approval"
  ],
  "source_of_truth": {
    "entrypoint_refs": [
      "AGENTS.md"
    ],
    "rules_refs": [
      "docs/operating-rules.md"
    ],
    "playbook_refs": [
      "docs/agent-playbook.md"
    ],
    "decision_refs": [
      "DECISIONS.md"
    ],
    "contract_refs": [
      "docs/api-surface.md"
    ]
  },
  "artifacts": {
    "context_files": [
      {
        "path": "src/api/users.ts",
        "kind": "code",
        "reason": "Primary implementation target",
        "required": true
      }
    ],
    "critical_context": [
      "All API responses must follow the documented envelope."
    ]
  },
  "expected_output": {
    "format": "summary",
    "success_definition": "Return the minimal change plan with validation notes.",
    "validation_required": false
  },
  "audit": {
    "source_marker": "[agent:application-implementer]",
    "trace_id": "trace_123",
    "generated_by": "coordinator"
  }
}
```

## Recommendation

Adopt the schema when:

- one task may run on more than one tool family
- you need resumability without replaying full transcripts
- you want a clean boundary between repository truth and execution transport
- you plan to use local connectors, managed-agent queues, or API orchestration

Keep text-only prompts for trivial tasks. Use the context pack when portability or auditability matters.
