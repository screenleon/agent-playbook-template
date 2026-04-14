---
name: observability
description: Use at the end of each task loop to emit a trace record for auditability, debugging, and future CI-based agent evaluation.
---

# Observability

Use this skill to produce trace records that capture what the agent did, why, and with what outcome. Trace records support post-hoc debugging, quality evaluation, and future CI-based automated review.

## When to trace

Produce a trace record at the end of every completed task, after the deliverable is emitted and self-reflection is done. This is a mandatory step — see `docs/agent-playbook.md` → Mandatory steps (step 14: Trace).

## Trace depth by scale

| Scale | Trace depth | Storage |
|-------|-------------|---------|
| Small | **Minimal** — inline in task completion summary | No separate file |
| Medium | **Standard** — structured trace block in output | Optional `.agent-trace/` file |
| Large | **Full** — structured trace file with per-role breakdown | `.agent-trace/` file recommended |

### Storage location

By default, trace files go in `.agent-trace/` at the repository root. If the directory does not exist, create it on first use.

Filename convention: `YYYY-MM-DD-<short-task-slug>.yaml`

## Trace format

### Minimal trace (Small tasks)

Embed directly in the task completion summary:

```text
**Trace**: scale=Small | roles=[application-implementer] | files=[path/to/file.ts] | validation=pass | decisions=none
```

### Standard trace (Medium tasks)

```yaml
task: "<one-sentence objective>"
date: "YYYY-MM-DD"
scale: Medium
trust_level: "<supervised | semi-auto | autonomous>"
roles_invoked:
  - <role-name>
files_changed:
  - <file-path>
decisions_made:
  - "<DECISIONS.md entry reference>"
validation_outcome: "<pass | fail | not-run>"
reflection_summary:
  correctness: "<pass | fail>"
  consistency: "<pass | fail>"
  adherence: "<pass | fail>"
  completeness: "<pass | fail>"
isolation_status: "<clean | violation | relaxed>"
risks_accepted:
  - "<risk description, or empty>"
```

### Full trace (Large tasks)

Extends the standard trace with per-role step breakdown:

```yaml
task: "<one-sentence objective>"
date: "YYYY-MM-DD"
scale: Large
trust_level: "<supervised | semi-auto | autonomous>"
steps:
  - role: "<role-name>"
    action: "<plan | critique | implement | review | document>"
    decisions_made:
      - "<DECISIONS.md entry reference>"
    files_changed:
      - "<file-path>"
    reflection_summary:
      correctness: "<pass | fail>"
      consistency: "<pass | fail>"
      adherence: "<pass | fail>"
      completeness: "<pass | fail>"
    handoff_target: "<next role, or 'user'>"
  - role: "<next role>"
    action: "..."
    # ...
validation_outcome: "<pass | fail | not-run>"
risks_accepted:
  - "<risk description, or empty>"
checkpoint_gates_hit:
  - gate: "<gate name>"
    action: "<approved | auto-proceeded | blocked>"
isolation_status: "<clean | violation | relaxed>"
```

## Fields reference

| Field | Required | Description |
|-------|----------|-------------|
| `task` | Yes | One-sentence task description |
| `date` | Yes | ISO date |
| `scale` | Yes | Small / Medium / Large |
| `trust_level` | Standard+ | Active trust level for this task |
| `roles_invoked` | Standard+ | List of roles that participated |
| `files_changed` | Yes | Files modified during the task |
| `decisions_made` | Yes | References to DECISIONS.md entries (empty list if none) |
| `validation_outcome` | Yes | pass / fail / not-run |
| `reflection_summary` | Standard+ | Self-reflection rubric results |
| `isolation_status` | Standard+ | clean / violation / relaxed — context isolation compliance |
| `risks_accepted` | Standard+ | Risks acknowledged but not mitigated |
| `steps` | Full only | Per-role breakdown |
| `checkpoint_gates_hit` | Full only | Which gates were triggered and their outcome |

## What NOT to trace

- Do not trace secrets, tokens, or credentials.
- Do not trace full file contents — only paths.
- Do not trace raw conversation history — only structured summaries.
- Do not include `duration` or timing estimates — agents cannot measure wall-clock time accurately.

## Integration with CI evaluation

Trace files in `.agent-trace/` can be consumed by CI pipelines for automated quality scoring. The trace format is intentionally simple YAML to allow easy parsing without specialized tooling.

### CI integration protocol

#### Trace file naming convention

For CI consumption, use a two-part filename:

```text
<taskId>-<role>.trace.yaml
```

Examples: `feat-auth-001-feature-planner.trace.yaml`, `feat-auth-001-risk-reviewer.trace.yaml`

The `YYYY-MM-DD-<short-task-slug>.yaml` naming from the storage convention above is for human-readable archives. When CI integration is active, prefer the `taskId-role` naming to enable per-role trace collection.

#### CI step workflow

1. **Collect** — glob `.agent-trace/*.trace.yaml` from the working tree or build artifacts.
2. **Parse** — read each YAML file. Validate that required fields (`task`, `scale`, `validation_outcome`, `decisions_made`) are present.
3. **Score** — evaluate each trace against a quality rubric:
   - `validation_outcome: fail` → severity-high
   - Multiple `reflection_summary` failures (≥ 2 of 4 dimensions) → severity-medium
   - Empty `decisions_made` when `scale ≥ Medium` → severity-low (possible missing documentation)
4. **Report** — output a summary (PR comment, CI artifact, or both).
5. **Exit** — use the exit-code contract below.

#### Exit-code contract

| Exit code | Meaning |
|---|---|
| `0` | All traces pass — no severity-high findings |
| `1` | At least one severity-high finding |
| `2` | Parse error — a trace file is malformed or missing required fields |

#### Review summary format

The CI step should produce a machine-readable summary:

```yaml
review_date: "YYYY-MM-DD"
traces_analyzed: <count>
findings:
  - trace_file: "<filename>"
    severity: "<high | medium | low>"
    reason: "<one-line description>"
exit_code: <0 | 1 | 2>
```
