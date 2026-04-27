# Coding Discipline

Global rules that govern individual agent coding behavior: how to reason before acting,
how to scope changes, and how to define completion. These rules apply across all domains
and adapters.

Inspired by Andrej Karpathy's observation that LLM agents "make wrong assumptions on your
behalf and just run along with them." The rules below create friction at the right moments.

## Rules

### Rule: GCODE-001 — Surface Assumptions Before Acting

- Owner layer: Global
- Scope: all coding tasks where the request contains ambiguity, multiple valid interpretations, or unstated scope
- Stability: core
- Status: active
- Directive: Before writing any code, state the assumptions you are making. If a request has more than one reasonable interpretation, list them and ask the user to confirm before proceeding. Do not silently pick one path and run.
- Rationale: Silent assumption errors compound — a wrong interpretation at step 1 produces a diff the user must fully discard at step N. Surfacing the fork early costs one message and saves a full rewrite.
- Conflict handling: In `autonomous` execution mode, brief the user on assumptions at task start and proceed only if no blocking ambiguity exists. A blocking ambiguity (scope undefined, conflicting requirements, destructive consequence unclear) is a hard stop regardless of trust level.
- Example: Request is "add export feature." Before writing code, state: "I'm assuming CSV export of the current table view, server-side, no background job. Correct?" Then wait for confirmation.
- Non-example: Silently implement a full async export pipeline with S3 upload because "it's more scalable."

### Rule: GCODE-002 — Minimum Code, No Speculation

- Owner layer: Global
- Scope: all implementation tasks
- Stability: core
- Status: active
- Directive: Write the minimum code that solves the stated problem. Do not add unrequested features, future-proofing abstractions, configuration systems, or generalization layers unless the task explicitly requires them. A senior engineer reviewing the diff should not find any code that does not trace back to the stated requirement.
- Rationale: Speculative code adds surface area, introduces bugs, and forces the user to understand and maintain things they never asked for. Three similar lines are better than a premature abstraction.
- Conflict handling: If a minimal solution would require a second pass to extend (e.g., a hard-coded value that will obviously need to be configurable soon), flag it as a known limitation rather than silently building the full system.
- Example: A discount function needs one conditional. Write one conditional.
- Non-example: Introduce a `DiscountStrategy` interface, a factory, and a config file because "discounts might get more complex."

### Rule: GCODE-003 — Surgical Changes Only

- Owner layer: Global
- Scope: all modifications to existing code
- Stability: core
- Status: active
- Directive: Modify only the code required by the task. Do not reformat, rename, reorganize, add type hints, remove dead code, or refactor sections that are not directly touched by the requested change — even if those sections look messy. Only clean up dead code that your own change created.
- Rationale: Unrelated edits inflate the diff, create merge conflicts, and obscure the intent of the change. Code review becomes harder; regressions become harder to attribute.
- Conflict handling: If pre-existing code is a direct blocker to the task (e.g., an incorrect type signature you must call), fixing it is in scope. Record the reason in the commit message. If cleanup is genuinely warranted, propose it as a separate task.
- Example: Fixing an empty-email bug means patching the email validator. The surrounding function has inconsistent naming — leave it.
- Non-example: Fix the bug and also rename variables, add docstrings, sort imports, and extract a helper that was not needed for the fix.

### Rule: GCODE-004 — Define Success Criteria Before Executing

- Owner layer: Global
- Scope: any task that will take more than one tool call to complete
- Stability: core
- Status: active
- Directive: Before beginning a multi-step implementation, state the verifiable success criteria: what observable output, test result, or system state will confirm the task is done. Use those criteria as the loop termination condition, not "I think it looks right."
- Rationale: Vague completion signals lead to premature stops or endless polish loops. Explicit criteria let the agent iterate independently and let the user verify the outcome without re-reading all the code.
- Conflict handling: When working in `supervised` mode, present the success criteria to the user for approval before starting. In `semi-auto` and `autonomous` modes, state the criteria and proceed. If the criteria cannot be verified automatically (e.g., requires manual visual inspection), flag this before starting rather than claiming completion without verification.
- Example: "Success: `pytest tests/test_export.py` passes, a CSV is written to `/tmp/export_test.csv` containing the three expected rows, and no existing tests regress."
- Non-example: Implement the feature, eyeball it, and report "done" without running any verification.

### Rule: GCODE-005 — Autonomous Loop: Advance/Discard and Timeout

- Owner layer: Global
- Scope: autonomous execution loops — iterative experiments, repair cycles, or any multi-attempt task running without continuous human oversight
- Stability: core
- Status: active
- Directive: In each loop iteration, define one measurable outcome metric before starting. After the iteration completes: if the metric improved, commit and advance; if it did not improve, revert the working-tree changes and discard. Never silently keep a change that did not improve the metric. Set an explicit timeout per iteration; if the iteration exceeds the timeout, treat it as a discard and move on. Within this scope, prefer a change that improves the metric through deletion over one that improves it by adding complexity — but do not delete code that was not created by the current iteration (see GCODE-003).
- Rationale: Autonomous loops without an explicit advance/discard decision rule accumulate ambiguous state — partial improvements, uncommitted changes, and unverifiable progress. Karpathy's autoresearch pattern demonstrates that a tight keep/discard loop with a single metric produces more reliable autonomous progress than open-ended iteration.
- Conflict handling: When the task has no single measurable metric (e.g., a refactor with no performance target), define a proxy: "existing tests continue to pass and diff size decreases." If no proxy is definable, do not run the task autonomously — trigger the scope-expansion STOP gate and wait for human framing before proceeding. Reverting uncommitted working-tree changes (e.g., `git restore .`) is not subject to the destructive-action approval gate because no committed history is lost; however, resetting committed history (e.g., `git reset --hard`) is an always-dangerous operation and requires the same approval as defined in `docs/rules-quickstart.md` → Always-dangerous operations.
- Example: Each experiment runs for ≤5 minutes. If `val_bpb` improves: `git commit`, continue. If it does not: `git restore .` (uncommitted changes only), log the attempt, try next idea.
- Non-example: Run 10 iterations, keep some changes from each, end up with a mixed state where it is unclear which change caused which effect. Or: use `git reset --hard` without the destructive-action approval gate.

### Rule: GCODE-006 — Session Hygiene: Reset After Repeated Failure

- Owner layer: Global
- Scope: any task where the same issue has been attempted and failed more than once within the current session
- Stability: core
- Status: active
- Directive: If the same issue causes two consecutive failed correction attempts — the agent tried a fix, was corrected, tried again, and was corrected again — stop. Do not attempt a third fix in the same session. Summarize: what the issue is, what was tried, and what was learned. Ask the user to start a fresh session with a sharper prompt. Use subagents for exploration tasks that would otherwise flood the main context with dozens of file reads.
- Rationale: Long sessions with accumulated failed attempts perform worse than fresh sessions with a better problem statement. A third attempt after two failures rarely succeeds and consumes context that poisons subsequent turns. Boris Cherny (Claude Code creator) observes that context is the primary constraint on agent performance.
- Conflict handling: "Same issue" means the root cause is the same, not the surface symptom. A fix that addresses the root cause differently than previous attempts is a new attempt, not a third failure. When in doubt, label the attempt and state the root hypothesis explicitly. This rule governs **user-prompted correction loops** (human reviews and asks to re-try); the stuck-escalation gate in `docs/operating-rules.md` (3 failed attempts) governs **autonomous validation loops** (agent retries a failing test or lint check without human involvement). These are independent counters and do not replace each other. If a multi-step plan is in progress past the plan-approval gate, do not recommend a full session reset — instead, stop, present the unresolved issue as a scope-reduction checkpoint, and wait for user guidance.
- Example: Two attempts to fix a flaky import resolved the symptom but the test still fails. Stop: "I've tried X and Y. Both failed at the same root cause — the module loading order. Please reset and provide more context about the import graph."
- Non-example: Keep trying minor variations of the same approach four times, each time slightly adjusting the fix without changing the underlying hypothesis. Or: recommend a session reset mid-way through an approved 10-step plan because one sub-step failed twice.

### Rule: GCODE-007 — CI Parity: Mirror CI Checks Locally Before Claiming Completion

- Owner layer: Global
- Scope: any code change in a repository that has CI configuration (`.github/workflows/`, `Jenkinsfile`, `.circleci/`, `Makefile` CI targets, or equivalent)
- Stability: behavior
- Status: active
- Directive: Before starting work in a repository, discover what CI checks are configured and what commands they run. Include passing those checks in the success criteria defined by GCODE-004. Before claiming a task complete, run the same commands locally that CI would run (tests, lint, type-check, build). If CI later runs on a pushed branch and fails, treat the failure as a reopened task — not as a post-delivery surprise. Never claim completion based on local tests alone when CI would run additional checks that were not executed.
- Rationale: CI failures after merge or push cause rollbacks, blocked pipelines, and team disruption. Discovering CI configuration upfront costs one file read; ignoring it costs a revert, a re-review, and broken confidence. The success criteria in GCODE-004 are only complete if they include what the repo's CI would assert.
- Conflict handling: If CI configuration exists but the commands cannot be run locally (e.g., requires cloud credentials, specific runners, or a full cluster), state this explicitly before starting: "CI runs X which I cannot replicate locally — local validation will cover Y only." Do not silently skip CI discovery. In adapter environments without shell access, read the CI config file, list the checks that would run, and state which ones were verified locally and which were not. If CI results arrive after a push and show failures, address root causes before marking any dependent task complete.
- Example: Repo has `.github/workflows/ci.yml` running `npm test && npm run lint && npm run typecheck`. Before claiming the task done, run all three locally. If `npm run typecheck` fails, fix it — do not push a passing test run that would fail CI.
- Non-example: Run `pytest` locally, see green, push and declare done — ignoring that CI also runs `flake8` and `mypy` which would fail on the new code.
