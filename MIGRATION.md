# Migration Guide

This document describes breaking changes and migration steps between notable
releases of the agent-playbook-template. Follow the relevant section when
upgrading an adopted repository.

For full release notes, see `CHANGELOG.md`.

---

## Upgrading past 0.17.x — adapter-neutral observability and evals

This release group adds measurement and governance-evaluation primitives
that work across ALL adapters (not just claude-code). No breaking changes;
everything is additive.

### New files (all optional, all adapter-neutral)

| File | Purpose |
|------|---------|
| `docs/schemas/trace.schema.yaml` | Canonical trace format — implicit before, explicit now |
| `scripts/trace-query.py` | Analytics over `.agent-trace/*.trace.yaml` (skill hit rate, gate activations, failure families, budget usage, role transitions, isolation) |
| `scripts/trace_query_impl.py` | Shared zero-dep YAML parser module (used by trace-query and score-eval) |
| `scripts/decisions-conflict-check.py` | Pre-plan contradiction detector against `DECISIONS.md` |
| `scripts/run-evals.sh` | Adapter-neutral eval runner (uses `$AGENT_INVOKE` contract) |
| `scripts/score-eval.py` | Compares trace against `expected-behavior.yaml` |
| `evals/README.md` | Framework documentation |
| `evals/schema/expected-behavior.schema.yaml` | Schema for per-task expectations |
| `evals/tasks/*/` | 6 seed fixtures (3 scales + 3 traps) |
| `evals/adapters/manual.sh` | Works with any tool — prints prompt, waits for trace |
| `evals/adapters/generic-cli.sh` | Template wrapper for any CLI-based runtime |

### Action required

- **None for safety** — all additions are opt-in.
- **Recommended**: wire `scripts/decisions-conflict-check.py` into your
  pre-plan routine (any tool, any adapter). It makes the contradiction
  check genuinely verifiable instead of relying on the agent to remember.
- **Recommended**: if your adapter emits traces, extend them to include
  the new optional `budget`, `failure_families`, and `eval_id` fields
  when the information is available. Downstream tooling degrades
  gracefully if those fields are absent.
- **Optional**: to use the evals framework, copy `evals/adapters/generic-cli.sh`,
  edit the `AGENT_CMD` line for your tool, and run
  `AGENT_INVOKE="bash evals/adapters/<yours>.sh" bash scripts/run-evals.sh`.

### Behavior change: error-recovery "3 strikes" is now family-aware

`skills/error-recovery/SKILL.md` now explicitly requires the failure-family
check between retries. Cosmetic differences (line numbers, addresses) no
longer accidentally "reset" the attempt counter. Adapters that cannot run
shell should emulate the classification natively and record
`failure_families[]` in the trace.

This mirrors the conceptual rule that was already in `docs/operating-rules.md`
— only the execution step became explicit.

---

## Upgrading to 0.17.x

### New scripts added

The following scripts were added and can be copied into your repository:

| Script | Purpose |
|--------|---------|
| `scripts/validate-prompt-budget.py` | Validates `prompt-budget.yml` schema |
| `scripts/budget-report.sh` | Estimates token cost per layer |
| `scripts/decisions-context.sh` | Extracts compact contradiction-check context |
| `harness/core/failure-family-detect.sh` | Reference implementation for `repeated_failed_fix_loop` |

**Action required**: Copy any scripts you want. None of them break existing behavior if omitted.

### New docs added

| File | Purpose |
|------|---------|
| `docs/adapter-capability-matrix.md` | Comparison table for all 6 adapters |
| `examples/anti-patterns.md` | Common adoption mistakes and corrections |
| `MIGRATION.md` (this file) | Upgrade guide |

**Action required**: None — informational docs, no breaking changes.

### Adapter conformance checker

A single unified conformance script at `harness/core/conformance.sh` replaces the
previous per-adapter `conformance.sh` files. It auto-detects the active adapter via
`detect-tool.sh` or accepts an explicit `--adapter <name>` flag:

```bash
bash harness/core/conformance.sh                    # auto-detect
bash harness/core/conformance.sh --adapter cursor   # explicit
```

### Security baseline expanded

`rules/global/security-baseline.md` now has 7 rules (GSEC-001 through GSEC-007),
covering supply chain (OWASP A06), input validation and access control (OWASP A03/A01),
security misconfiguration (OWASP A05), security logging (OWASP A09), and prompt injection.

**Action required**: Review the new rules. If any conflict with existing project
decisions, add an override in `project/project-manifest.md` with the `Overrides:` annotation.

### Prompt injection global rule added

A new file `rules/global/prompt-injection.md` defines GSEC-PI-001. Agents are
instructed to alert users when they detect prompt injection attempts in tool output.

**Action required**: None if you want the default behavior. Override in
`project/project-manifest.md` if your project requires different handling (e.g.,
a sandbox that processes untrusted text intentionally).

### Skills: `depends_on` / `commonly_followed_by` metadata

Key SKILL.md files now declare `depends_on` and `commonly_followed_by` in their
YAML frontmatter. These are informational — agents can use them to improve loading
order decisions.

**Action required**: None. Existing skill loading is not affected.

### CI: shellcheck and schema validation

`.github/workflows/rule-governance.yml` now includes two new jobs:
- `shellcheck` — lints all `scripts/*.sh` and `harness/**/*.sh` files
- `validate-prompt-budget` — runs `scripts/validate-prompt-budget.py --all`

**Action required**: After copying the updated CI file, run `shellcheck` locally
on any custom shell scripts you have added. Fix any warnings before the first CI run.

---

## Upgrading from 0.15.x to 0.16.x

### project-manifest.md as constraint source of truth

`docs/operating-rules.md` and multiple skill files were updated to point to
`project/project-manifest.md` as the single source of truth for project-specific
constraints. Prior versions kept constraints in a mix of `docs/operating-rules.md`
inline sections and the manifest.

**Action required**:
1. Move any project-specific constraint text from `docs/operating-rules.md` into
   `project/project-manifest.md` under `Non-negotiable constraints`.
2. Ensure `docs/operating-rules.md` points to the manifest rather than duplicating rules.

### adoption-audit.sh now checks prompt-budget.yml

The `--strict` audit flag now validates `execution_mode` and `budget.profile` in
`prompt-budget.yml`. If you copied the file from an older template, verify the values
match valid enum options (`supervised | semi-auto | autonomous` and
`nano | minimal | standard | full`).

---

## Upgrading from 0.14.x to 0.15.x

### ARCHITECTURE.md content replaced

The placeholder `ARCHITECTURE.md` was replaced with a concrete module map for the
template repository. Adopters should replace it with their own module map.

**Action required**: If you copied the old placeholder text, replace it with your
actual architecture. The adoption audit in `--strict` mode will flag the old template
text.

### DECISIONS.md example moved to DECISIONS_ARCHIVE.md

The in-file example decision was moved to `DECISIONS_ARCHIVE.md` so adopters
inherit a clean active log.

**Action required**: If you already have real decisions in your `DECISIONS.md`,
no action needed. If you still have only the template example entry, remove it
and add your first real decision.

---

## Upgrading from 0.13.x to 0.14.x

### Compaction summary template added

`docs/agent-templates.md` now defines a canonical compaction summary template.
Multiple skill files (memory-and-state, operating-rules) were updated to reference
it as the single source of truth instead of defining the format inline.

**Action required**: If your project has custom compaction instructions in skill
files, align them to the new canonical template or document the override explicitly.

---

## General upgrade checklist

When pulling any template update into your adopted repository:

1. Compare your `docs/operating-rules.md` with the upstream version — look for
   new mandatory rules or gate changes.
2. Compare your `prompt-budget.yml` schema fields with the upstream reference.
3. Run `bash scripts/adoption-audit.sh --strict` and resolve any new warnings.
4. Run `python3 scripts/validate-prompt-budget.py` if available.
5. Add a `DECISIONS.md` entry if the upgrade changes any constraint your team
   has previously decided to override.
