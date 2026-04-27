---
name: rule-lint
description: "Use to health-check the quality of agent rule files in rules/. Triggers: 'lint rules', 'check for stale rules', 'rule contradictions', 'prune rules', or any periodic maintenance of the rules/ directory."
---

# Rule Lint

Periodically audit the `rules/` directory for quality issues: contradictions between rules,
stale rules that no longer apply, orphan rules with no enforcement path, and rules so long
or vague they are effectively ignored.

Adapted from Karpathy's LLM Wiki lint pattern — the same health-check discipline that keeps
a knowledge base from rotting applies to an agent rule set.

## When to run

- Before a major release or template version bump
- When a rule produces unexpected agent behavior in production
- When the total rule-file line count exceeds 600 lines (a signal that rules are bloating)
- On explicit request ("lint the rules", "prune outdated rules")

## Lint checks

Run all six checks in order. For each issue found, record it in the lint report (see Output
format below) before moving on.

### L-1 Contradiction check

For each pair of rules across all files in `rules/`:

- Does rule A instruct behavior that rule B prohibits?
- Does rule A's scope overlap with rule B's scope in a way that makes both unenforceable simultaneously?

If a contradiction is found: record both rule IDs, describe the conflict, and propose a resolution (merge, scope-narrow, or explicit precedence annotation).

### L-2 Stale rule check

For each rule, assess whether its directive still applies given the current codebase and
operating context:

- Does the rule reference a pattern, tool, or workflow that no longer exists?
- Does the rule address a failure mode that a platform upgrade has since eliminated?
- Has the rule been superseded by a more specific rule in a lower layer (Domain or Project)?

Mark stale rules as candidates for deprecation. Do not delete — record in the lint report.

### L-3 Orphan rule check

For each rule, verify it has an enforcement path:

- Is the rule referenced in `docs/operating-rules.md`, `AGENTS.md`, or an adapter-specific
  instruction file?
- Is the rule reachable from the agent's context-loading path (i.e., will the agent actually
  see it)?

Orphan rules (no reference, no load path) are dead weight. Record them as removal candidates.

### L-4 Bloat check

For each rule:

- Does the Directive field fit in two sentences? If not, is the extra length genuinely necessary?
- Does the Example/Non-example pair illustrate something the Directive does not already make clear?
- Would a senior engineer reading this rule be able to apply it without re-reading it three times?

Rules that fail this check are candidates for rewriting, not deletion. Record the rule ID and
the specific verbosity issue.

### L-5 Coverage gap check

Review the failure modes that rules are meant to prevent. Ask:

- Are there known agent failure patterns in this project's DECISIONS.md or git history that
  no current rule addresses?
- Are there categories in `docs/operating-rules.md` (e.g., safety rails, coding discipline)
  that have no corresponding rule in `rules/`?

**Adapter note**: The DECISIONS.md scan is adapter-neutral (file read only). The git history
scan requires shell access (`git log`). If git CLI is not available in the current adapter
environment, skip the git-history scan and note "git history unavailable — coverage gap
analysis based on DECISIONS.md only" in the lint report. Do not silently omit this
limitation.

Record each gap as a candidate for a new rule.

### L-6 Layer placement check

For each rule, verify it is in the correct layer:

- **Global rules** (`rules/global/`) must apply to nearly every repository. If a rule depends
  on this specific repo's tech stack or conventions, it belongs in Domain or Project.
- **Domain rules** (`rules/domain/`) must be reusable across repos in the same domain. If a
  rule is specific to this repo only, it belongs in `project/project-manifest.md`.

Record misplaced rules as relocation candidates.

## Output format

Produce a lint report in this structure:

```markdown
## Rule Lint Report — YYYY-MM-DD

### Contradictions
- [RULE-ID-A] vs [RULE-ID-B]: <description of conflict>. Proposed resolution: <action>.

### Stale rules
- [RULE-ID]: <reason>. Proposed action: deprecate / merge into [RULE-ID].

### Orphan rules
- [RULE-ID]: not referenced in any load path. Proposed action: add reference or remove.

### Bloat
- [RULE-ID]: <specific verbosity issue>. Proposed action: rewrite directive to ≤2 sentences.

### Coverage gaps
- <failure mode>: no rule covers this. Proposed action: add rule under <layer>.

### Layer misplacements
- [RULE-ID]: currently in <wrong layer>, belongs in <correct layer>.

### Summary
- Issues found: <N>
- Critical (contradictions, orphans): <N>
- Maintenance (stale, bloat, gaps): <N>
- Recommended next step: <action>
```

If no issues are found in a section, write "None."

## Resolution protocol

After producing the lint report:

1. **Do not auto-fix.** Present the report to the user and wait for approval before making changes. In `autonomous` execution mode, this step maps to a **scope-expansion STOP gate** — the agent must halt and emit the lint report as a deliverable, then wait for explicit instruction before applying any changes. This is not an advisory; it is an unconditional stop regardless of `autonomous_mode` settings, because rule changes affect all downstream tasks in the session.
2. For approved fixes, apply them using GCODE-003 (surgical changes only — fix the specific rule, do not refactor surrounding rules).
3. After applying fixes, re-run only the checks that were affected to confirm resolution.
4. Record significant rule changes (deprecations, merges, new rules) in `DECISIONS.md`.

## Pruning principle

When evaluating whether to keep a rule, ask: "Would removing this rule cause the agent to
make a mistake?" If the answer is no — because the behavior is agent-native, covered by a
more specific rule, or simply obvious — remove it. A concise rule set that fits in one
context window is more effective than an exhaustive one that gets skipped.

Boris Cherny's heuristic: keep the total instruction file under 300 lines. Over 500 lines
and the agent is fighting its own config.
