#!/usr/bin/env python3
"""
build-context-pack.py

Adapter-neutral, budget-aware context-pack builder. Reads canonical repo
context (AGENTS.md, rules/, project/project-manifest.md, DECISIONS.md) and
the task-declared file list, then emits a deterministic JSON pack that
conforms to docs/schemas/context-pack.schema.json (version 1.1.0).

Scope (by design):
    - Reads ONLY canonical repo files + the args passed in.
    - Does NOT read IDE state, editor buffers, session memory, or any
      adapter-specific runtime.
    - Deterministic: identical inputs produce byte-identical output.

Usage:
    python3 scripts/build-context-pack.py \\
        --pack-id pk-0001 \\
        --generated-at 2026-04-22T00:00:00Z \\
        --role application-implementer \\
        --intent-mode implement \\
        --scale Small \\
        --objective "Fix typo in greeting string." \\
        --task-file evals/tasks/small-typo-fix/task.md \\
        --context-file docs/example-task-walkthrough.md:doc:reference \\
        --allowed-path src/ \\
        --non-goal "Do not refactor unrelated callers." \\
        --acceptance "Greeting reads correctly." \\
        --output-format patch \\
        --success-definition "Patch applies and test passes." \\
        --validation-required \\
        --trace-id trace-0001 \\
        --source-marker cli \\
        --generated-by screenleon

Exit codes:
    0  Pack written successfully.
    2  Input error (missing required arg, invalid file, etc.).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

BUILDER_VERSION = "1.0.0"
SCHEMA_VERSION = "1.1.0"

# Rough token estimate multiplier — matches scripts/budget-report.sh.
DEFAULT_TOKEN_MULTIPLIER = 1.35

# Budget targets per profile when prompt-budget.yml is absent or silent.
# These are intentionally conservative starter values; real projects should
# override via prompt-budget.yml.
DEFAULT_PROFILE_BUDGETS = {
    "nano": 2_000,
    "minimal": 6_000,
    "standard": 12_000,
    "full": 24_000,
}

ROLE_ENUM = {
    "feature-planner", "backend-architect", "application-implementer",
    "ui-image-implementer", "integration-engineer", "documentation-architect",
    "risk-reviewer", "critic",
}
INTENT_ENUM = {"analyze", "implement", "review", "document"}
SCALE_ENUM = {"Small", "Medium", "Large"}
EXEC_MODE_ENUM = {"supervised", "semi-auto", "autonomous"}
PROFILE_ENUM = {"nano", "minimal", "standard", "full"}
OUTPUT_FORMAT_ENUM = {"plan", "patch", "review", "summary", "json", "markdown", "other"}
FILE_KIND_ENUM = {
    "doc", "code", "config", "schema", "test", "decision", "output",
    "example", "other",
}


# ---------------------------------------------------------------------------
# Input dataclass
# ---------------------------------------------------------------------------

@dataclass
class BuilderInput:
    pack_id: str
    generated_at: str
    role: str
    intent_mode: str
    scale: str
    execution_mode: str
    budget_profile: str
    objective: str
    scope_summary: str
    allowed_paths: list[str]
    blocked_paths: list[str]
    non_goals: list[str]
    acceptance: list[str]
    context_files: list[tuple[str, str, str, bool]]  # (path, kind, reason, required)
    critical_context: list[str]
    output_format: str
    success_definition: str
    validation_required: bool
    response_sections: list[str]
    trace_id: str
    source_marker: str
    generated_by: str
    parent_pack_id: str | None
    context_version: str | None
    max_decisions: int
    target_tokens: int
    extra_constraints: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Canonical repo readers
# ---------------------------------------------------------------------------

def _read_text(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8")
    except OSError:
        return ""


def _list_rules(repo: Path, profile: str) -> list[str]:
    # Deterministic loading order across ALL profiles:
    #   nano    → docs/rules-nano.md
    #   minimal → docs/rules-quickstart.md + docs/rules-nano.md
    #   standard/full → nano + quickstart + operating-rules + layered files
    # Only return files that actually exist in the repo so the output stays
    # truthful across template and adopted repos.
    ordered: list[str] = []
    if profile == "nano":
        ordered = ["docs/rules-nano.md"]
    elif profile == "minimal":
        ordered = ["docs/rules-quickstart.md", "docs/rules-nano.md"]
    else:
        ordered = [
            "docs/rules-nano.md",
            "docs/rules-quickstart.md",
            "docs/operating-rules.md",
            "docs/agent-playbook.md",
        ]
        layered = []
        for sub in ("rules/global", "rules/domain"):
            d = repo / sub
            if d.is_dir():
                for f in sorted(d.iterdir()):
                    if f.is_file() and f.suffix == ".md":
                        layered.append(f.relative_to(repo).as_posix())
        ordered.extend(sorted(layered))
        pm = repo / "project" / "project-manifest.md"
        if pm.is_file():
            ordered.append(pm.relative_to(repo).as_posix())
    return [p for p in ordered if (repo / p).is_file()]


def _list_entrypoints(repo: Path) -> list[str]:
    candidates = ["AGENTS.md", "README.md", "ARCHITECTURE.md"]
    return [c for c in candidates if (repo / c).is_file()]


def _list_playbook_refs(repo: Path) -> list[str]:
    candidates = [
        "docs/agent-playbook.md",
        "docs/agent-templates.md",
    ]
    return [c for c in candidates if (repo / c).is_file()]


def _list_contract_refs(repo: Path) -> list[str]:
    # Schemas live under docs/schemas/. Listing them makes downstream
    # machine-readable outputs discoverable.
    d = repo / "docs" / "schemas"
    if not d.is_dir():
        return []
    return sorted(
        f.relative_to(repo).as_posix()
        for f in d.iterdir()
        if f.is_file() and f.suffix in (".json", ".yaml", ".yml")
    )


def _recent_decisions(repo: Path, max_n: int) -> list[tuple[str, str]]:
    # Returns [(heading, body)] for up to max_n most-recent DECISIONS entries.
    # DECISIONS.md convention: newest entries at the top, each starts with `## `.
    dp = repo / "DECISIONS.md"
    if not dp.is_file():
        return []
    text = re.sub(r"<!--.*?-->", "", dp.read_text(encoding="utf-8"), flags=re.DOTALL)
    entries: list[tuple[str, list[str]]] = []
    cur_heading: str | None = None
    cur_body: list[str] = []
    for line in text.splitlines():
        if line.startswith("## "):
            if cur_heading is not None:
                entries.append((cur_heading, cur_body))
            cur_heading = line[3:].strip()
            cur_body = []
        elif cur_heading is not None:
            cur_body.append(line)
    if cur_heading is not None:
        entries.append((cur_heading, cur_body))
    return [(h, "\n".join(b).strip()) for h, b in entries[:max_n]]


def _non_negotiables(repo: Path) -> list[str]:
    pm = repo / "project" / "project-manifest.md"
    if not pm.is_file():
        return []
    text = pm.read_text(encoding="utf-8")
    in_block = False
    out: list[str] = []
    for line in text.splitlines():
        if line.strip().lower().startswith("## non-negotiable"):
            in_block = True
            continue
        if in_block and line.startswith("## "):
            break
        if in_block:
            m = re.match(r"^[-*]\s+(.*)$", line.strip())
            if m:
                out.append(m.group(1).strip())
    return out


# ---------------------------------------------------------------------------
# Token estimation
# ---------------------------------------------------------------------------

def _estimate_tokens_from_path(repo: Path, rel: str, multiplier: float) -> int:
    p = repo / rel
    if not p.is_file():
        return 0
    text = p.read_text(encoding="utf-8", errors="replace")
    words = len(text.split())
    return int(words * multiplier)


def _estimate_tokens_from_text(text: str, multiplier: float) -> int:
    return int(len(text.split()) * multiplier)


# ---------------------------------------------------------------------------
# Selection / ranking
# ---------------------------------------------------------------------------

def _priority_for_kind(kind: str) -> int:
    # Lower is more important.
    return {
        "entrypoint": 1,
        "rules": 2,
        "playbook": 3,
        "manifest": 4,
        "decisions": 5,
        "context_file": 6,
        "contract": 7,
    }.get(kind, 9)


def _gather_candidates(
    repo: Path,
    inp: BuilderInput,
    multiplier: float,
) -> list[dict]:
    """Build the raw (possibly duplicate) candidate list.

    Each entry is a dict with stable keys: ref, priority, label, reason, tokens.
    """
    entrypoints = _list_entrypoints(repo)
    rules = _list_rules(repo, inp.budget_profile)
    playbook = _list_playbook_refs(repo)
    contracts = _list_contract_refs(repo)
    decisions = _recent_decisions(repo, inp.max_decisions)

    raw: list[dict] = []

    def _add(priority: int, ref: str, label: str, reason: str, tokens: int) -> None:
        raw.append({
            "ref": ref,
            "priority": priority,
            "label": label,
            "reason": reason,
            "tokens": tokens,
        })

    for ref in entrypoints:
        _add(_priority_for_kind("entrypoint"), ref, "entrypoint",
             "root entrypoint file",
             _estimate_tokens_from_path(repo, ref, multiplier))
    for ref in rules:
        _add(_priority_for_kind("rules"), ref, "rules",
             f"rule surface for profile={inp.budget_profile}",
             _estimate_tokens_from_path(repo, ref, multiplier))
    for ref in playbook:
        _add(_priority_for_kind("playbook"), ref, "playbook",
             "role routing / workflow reference",
             _estimate_tokens_from_path(repo, ref, multiplier))
    manifest_ref = "project/project-manifest.md"
    if (repo / manifest_ref).is_file():
        _add(_priority_for_kind("manifest"), manifest_ref, "manifest",
             "project-local constraints",
             _estimate_tokens_from_path(repo, manifest_ref, multiplier))
    for idx, (heading, body) in enumerate(decisions):
        ref = f"DECISIONS.md#{heading}"
        _add(_priority_for_kind("decisions") + idx, ref, "decisions",
             f"recent decision #{idx + 1}",
             _estimate_tokens_from_text(heading + "\n" + body, multiplier))
    for (path, _kind, reason, _required) in inp.context_files:
        _add(_priority_for_kind("context_file"), path, "context_file", reason,
             _estimate_tokens_from_path(repo, path, multiplier))
    for ref in contracts:
        _add(_priority_for_kind("contract"), ref, "contract",
             "machine-readable contract",
             _estimate_tokens_from_path(repo, ref, multiplier))
    return raw


def _dedupe_candidates(raw: list[dict]) -> list[dict]:
    """Merge duplicates by `ref`, keeping the entry with the lowest priority.

    Deterministic: ties on priority break on the existing entry's label
    alphabetical order so identical inputs always pick the same winner.
    """
    best: dict[str, dict] = {}
    for c in raw:
        ref = c["ref"]
        existing = best.get(ref)
        if existing is None:
            best[ref] = c
            continue
        # Lower priority wins; tie-break: stable label ordering.
        if (c["priority"], c["label"]) < (existing["priority"], existing["label"]):
            best[ref] = c
    return sorted(best.values(), key=lambda x: (x["priority"], x["ref"]))


def _build_selection_and_dropped(
    repo: Path,
    inp: BuilderInput,
    target_tokens: int,
    multiplier: float,
) -> tuple[list[dict], list[dict], dict[str, int]]:
    """Rank candidates and greedily fill within the target token budget.

    Deterministic: candidates are deduped by ref, then sorted by (priority,
    ref) so two identical invocations produce the same selection.
    """
    candidates = _dedupe_candidates(_gather_candidates(repo, inp, multiplier))

    selected: list[dict] = []
    dropped: list[dict] = []
    consumed = 0
    # Reserve 10% of target for critical context + output framing.
    working_target = int(target_tokens * 0.90) if target_tokens > 0 else 0
    # Track actual tokens included (post-truncation) per selected ref so
    # the rollup below reflects what the pack actually spent.
    label_by_ref: dict[str, str] = {c["ref"]: c["label"] for c in candidates}
    tokens_included: dict[str, int] = {}

    for cand in candidates:
        ref = cand["ref"]
        priority = cand["priority"]
        reason = cand["reason"]
        tokens = cand["tokens"]

        if working_target and consumed + tokens > working_target:
            remaining = max(0, working_target - consumed)
            if remaining >= 50:
                selected.append({
                    "ref": ref,
                    "priority": priority,
                    "reason": reason,
                    "truncated": True,
                    "truncation_method": "headings-only",
                })
                tokens_included[ref] = remaining
                consumed += remaining
            else:
                dropped.append({"ref": ref, "reason": "budget exhausted"})
            continue

        selected.append({
            "ref": ref,
            "priority": priority,
            "reason": reason,
            "truncated": False,
            "truncation_method": "none",
        })
        tokens_included[ref] = tokens
        consumed += tokens

    # Roll up by label using ONLY selected refs + their actual included tokens.
    by_kind: dict[str, int] = {}
    for ref, tokens in tokens_included.items():
        label = label_by_ref.get(ref, "other")
        by_kind[label] = by_kind.get(label, 0) + tokens

    allocation: dict[str, int] = {k: by_kind[k] for k in sorted(by_kind.keys())}
    allocation["reserve"] = max(0, target_tokens - consumed)

    return selected, dropped, allocation


# ---------------------------------------------------------------------------
# Pack assembly
# ---------------------------------------------------------------------------

def _canonical_json(obj: Any) -> str:
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def _sha256(s: str) -> str:
    return "sha256:" + hashlib.sha256(s.encode("utf-8")).hexdigest()


def _normalized_input_for_hash(inp: BuilderInput) -> dict[str, Any]:
    """Return a canonical, order-independent view of the builder inputs.

    Sort every list whose order is NOT semantically meaningful so that
    two CLI invocations that pass the same args in different orders
    produce the same input_hash. Lists where order IS semantic
    (response_sections, context_files which carry per-entry metadata)
    are kept as-is.
    """
    d = dict(inp.__dict__)
    for k in (
        "allowed_paths",
        "blocked_paths",
        "non_goals",
        "acceptance",
        "critical_context",
        "extra_constraints",
    ):
        if isinstance(d.get(k), list):
            d[k] = sorted(d[k])
    # context_files is a list of tuples; sort by path for stable ordering.
    if isinstance(d.get("context_files"), list):
        d["context_files"] = sorted(d["context_files"], key=lambda t: t[0])
    return d


def _compute_input_hash(inp: BuilderInput, repo_reads: dict[str, str]) -> str:
    # Hash a normalized view of the input + every repo file actually read.
    payload = {
        "input": _normalized_input_for_hash(inp),
        "reads": {k: hashlib.sha256(v.encode("utf-8")).hexdigest()
                  for k, v in sorted(repo_reads.items())},
        "builder_version": BUILDER_VERSION,
    }
    return _sha256(_canonical_json(payload))


def _assemble_pack(
    repo: Path,
    inp: BuilderInput,
) -> dict[str, Any]:
    # Total target: explicit --target-tokens wins, else the profile default.
    # Note: prompt-budget.yml defines PER-LAYER targets (layer1_target_tokens
    # etc.); mapping those onto a single context-pack total is ambiguous, so
    # we keep the pack's total as an explicit builder decision.
    target = inp.target_tokens if inp.target_tokens > 0 else DEFAULT_PROFILE_BUDGETS[inp.budget_profile]

    # Collect selected refs + token allocation.
    selected, dropped, allocation = _build_selection_and_dropped(
        repo, inp, target, DEFAULT_TOKEN_MULTIPLIER,
    )

    entrypoints = _list_entrypoints(repo)
    rules = _list_rules(repo, inp.budget_profile)
    playbook = _list_playbook_refs(repo)
    contracts = _list_contract_refs(repo)
    decisions = _recent_decisions(repo, inp.max_decisions)
    non_negs = _non_negotiables(repo)

    repo_reads: dict[str, str] = {}
    for ref in entrypoints + rules + playbook + contracts:
        p = repo / ref
        if p.is_file():
            repo_reads[ref] = p.read_text(encoding="utf-8", errors="replace")
    if (repo / "project" / "project-manifest.md").is_file():
        p = repo / "project" / "project-manifest.md"
        repo_reads[p.relative_to(repo).as_posix()] = p.read_text(encoding="utf-8", errors="replace")
    if (repo / "DECISIONS.md").is_file():
        repo_reads["DECISIONS.md"] = (repo / "DECISIONS.md").read_text(encoding="utf-8", errors="replace")

    decision_refs = [f"DECISIONS.md#{h}" for h, _ in decisions]

    all_constraints = sorted(set(non_negs + inp.extra_constraints))

    pack: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "pack_id": inp.pack_id,
        "generated_at": inp.generated_at,
        "objective": inp.objective,
        "role": inp.role,
        "intent_mode": inp.intent_mode,
        "task_scale": inp.scale,
        "execution_mode": inp.execution_mode,
        "budget_profile": inp.budget_profile,
        "approved_scope": {
            "summary": inp.scope_summary or inp.objective,
            "allowed_paths": sorted(inp.allowed_paths),
            "blocked_paths": sorted(inp.blocked_paths),
            # Sort these so order-independent CLI invocations produce
            # byte-identical packs. `response_sections` below keeps user
            # order because its order IS semantic (render order).
            "non_goals": sorted(inp.non_goals),
            "acceptance_criteria": sorted(inp.acceptance),
        },
        "constraints": all_constraints,
        "source_of_truth": {
            "entrypoint_refs": entrypoints,
            "rules_refs": rules,
            "playbook_refs": playbook,
            "decision_refs": decision_refs,
            "contract_refs": contracts,
        },
        "artifacts": {
            "context_files": [
                {
                    "path": path,
                    "kind": kind,
                    "reason": reason,
                    "required": bool(required),
                }
                for (path, kind, reason, required) in sorted(
                    inp.context_files, key=lambda x: x[0]
                )
            ],
            "critical_context": sorted(inp.critical_context),
        },
        "expected_output": {
            "format": inp.output_format,
            "success_definition": inp.success_definition,
            "validation_required": inp.validation_required,
            "response_sections": list(inp.response_sections),
        },
        "audit": {
            "source_marker": inp.source_marker,
            "trace_id": inp.trace_id,
            "generated_by": inp.generated_by,
        },
    }
    if inp.parent_pack_id:
        pack["audit"]["parent_pack_id"] = inp.parent_pack_id
    if inp.context_version:
        pack["audit"]["context_version"] = inp.context_version

    # Strip empty optional lists to keep output tight.
    if not pack["approved_scope"]["blocked_paths"]:
        pack["approved_scope"].pop("blocked_paths")

    # Determinism markers.
    input_hash = _compute_input_hash(inp, repo_reads)

    pack["orchestration"] = {
        "budget": {
            "profile": inp.budget_profile,
            "target_total_tokens": target,
            "allocated": allocation,
            "estimate_method": f"word_count*{DEFAULT_TOKEN_MULTIPLIER}",
        },
        "selection": selected,
        "dropped": dropped,
        "determinism": {
            "builder_version": BUILDER_VERSION,
            "input_hash": input_hash,
            "output_hash": "",  # filled below
        },
    }

    # Compute output_hash over the canonical form of the pack with
    # output_hash itself blanked so the hash remains reproducible.
    clone = json.loads(_canonical_json(pack))
    clone["orchestration"]["determinism"]["output_hash"] = ""
    pack["orchestration"]["determinism"]["output_hash"] = _sha256(_canonical_json(clone))

    return pack


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _parse_context_file(token: str) -> tuple[str, str, str, bool]:
    # Format: path[:kind[:reason[:required]]]
    parts = token.split(":", 3)
    path = parts[0]
    kind = parts[1] if len(parts) > 1 else "doc"
    reason = parts[2] if len(parts) > 2 else "context file declared in task"
    required = True
    if len(parts) > 3:
        v = parts[3].lower()
        required = v not in ("false", "0", "no", "optional")
    if kind not in FILE_KIND_ENUM:
        raise SystemExit(f"ERROR: kind '{kind}' not in {sorted(FILE_KIND_ENUM)}")
    return (path, kind, reason, required)


def _build_input(args: argparse.Namespace) -> BuilderInput:
    if args.role not in ROLE_ENUM:
        raise SystemExit(f"ERROR: role '{args.role}' not in {sorted(ROLE_ENUM)}")
    if args.intent_mode not in INTENT_ENUM:
        raise SystemExit(f"ERROR: intent_mode '{args.intent_mode}' not in {sorted(INTENT_ENUM)}")
    if args.scale not in SCALE_ENUM:
        raise SystemExit(f"ERROR: scale '{args.scale}' not in {sorted(SCALE_ENUM)}")
    if args.execution_mode not in EXEC_MODE_ENUM:
        raise SystemExit(f"ERROR: execution_mode '{args.execution_mode}' not in {sorted(EXEC_MODE_ENUM)}")
    if args.budget_profile not in PROFILE_ENUM:
        raise SystemExit(f"ERROR: budget_profile '{args.budget_profile}' not in {sorted(PROFILE_ENUM)}")
    if args.output_format not in OUTPUT_FORMAT_ENUM:
        raise SystemExit(f"ERROR: output_format '{args.output_format}' not in {sorted(OUTPUT_FORMAT_ENUM)}")

    objective = args.objective
    if args.task_file:
        p = Path(args.task_file)
        if not p.is_file():
            raise SystemExit(f"ERROR: task file not found: {p}")
        first_line = next(
            (ln.strip() for ln in p.read_text(encoding="utf-8").splitlines() if ln.strip()),
            "",
        )
        if not objective:
            objective = first_line
    if not objective:
        raise SystemExit("ERROR: --objective or --task-file is required")

    context_files = [_parse_context_file(t) for t in args.context_file]

    return BuilderInput(
        pack_id=args.pack_id,
        generated_at=args.generated_at,
        role=args.role,
        intent_mode=args.intent_mode,
        scale=args.scale,
        execution_mode=args.execution_mode,
        budget_profile=args.budget_profile,
        objective=objective,
        scope_summary=args.scope_summary or "",
        allowed_paths=list(args.allowed_path),
        blocked_paths=list(args.blocked_path),
        non_goals=list(args.non_goal),
        acceptance=list(args.acceptance),
        context_files=context_files,
        critical_context=list(args.critical),
        output_format=args.output_format,
        success_definition=args.success_definition,
        validation_required=bool(args.validation_required),
        response_sections=list(args.response_section),
        trace_id=args.trace_id,
        source_marker=args.source_marker,
        generated_by=args.generated_by,
        parent_pack_id=args.parent_pack_id,
        context_version=args.context_version,
        max_decisions=args.max_decisions,
        target_tokens=int(args.target_tokens) if args.target_tokens else 0,
        extra_constraints=list(args.constraint),
    )


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Build a deterministic context pack (schema 1.1.0).",
    )
    ap.add_argument("--repo-root", default=None,
                    help="Path to repo root (default: auto-detect via .git).")
    ap.add_argument("--pack-id", required=True)
    ap.add_argument("--generated-at", required=True,
                    help="ISO-8601 UTC timestamp. Required for determinism.")
    ap.add_argument("--role", required=True)
    ap.add_argument("--intent-mode", required=True)
    ap.add_argument("--scale", required=True)
    ap.add_argument("--execution-mode", default="semi-auto")
    ap.add_argument("--budget-profile", default="standard")
    ap.add_argument("--objective", default="")
    ap.add_argument("--task-file", default=None)
    ap.add_argument("--scope-summary", default="")
    ap.add_argument("--allowed-path", action="append", default=[])
    ap.add_argument("--blocked-path", action="append", default=[])
    ap.add_argument("--non-goal", action="append", default=[])
    ap.add_argument("--acceptance", action="append", default=[])
    ap.add_argument("--context-file", action="append", default=[],
                    help="Format: path[:kind[:reason[:required]]].")
    ap.add_argument("--critical", action="append", default=[])
    ap.add_argument("--constraint", action="append", default=[],
                    help="Extra constraint strings appended to manifest non-negotiables.")
    ap.add_argument("--output-format", default="markdown")
    ap.add_argument("--success-definition", required=True)
    ap.add_argument("--validation-required", action="store_true")
    ap.add_argument("--response-section", action="append", default=[])
    ap.add_argument("--trace-id", required=True)
    ap.add_argument("--source-marker", default="cli")
    ap.add_argument("--generated-by", required=True)
    ap.add_argument("--parent-pack-id", default=None)
    ap.add_argument("--context-version", default=None)
    ap.add_argument("--max-decisions", type=int, default=5)
    ap.add_argument("--target-tokens", type=int, default=0,
                    help="Override total token target for the pack. "
                         "Default: DEFAULT_PROFILE_BUDGETS[profile]. "
                         "prompt-budget.yml holds per-layer targets, not a "
                         "pack total, so it is not auto-read.")
    ap.add_argument("--output", default="-",
                    help="Output file path (default: stdout).")
    ap.add_argument("--pretty", action="store_true",
                    help="Pretty-print output with 2-space indent. Non-canonical form.")
    args = ap.parse_args()

    repo = Path(args.repo_root).resolve() if args.repo_root else _auto_repo_root()
    if not repo.is_dir():
        raise SystemExit(f"ERROR: repo root does not exist: {repo}")

    inp = _build_input(args)
    pack = _assemble_pack(repo, inp)

    if args.pretty:
        serialized = json.dumps(pack, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    else:
        serialized = _canonical_json(pack) + "\n"

    if args.output == "-":
        sys.stdout.write(serialized)
    else:
        Path(args.output).write_text(serialized, encoding="utf-8")

    return 0


def _auto_repo_root() -> Path:
    here = Path.cwd()
    for p in [here, *here.parents]:
        if (p / ".git").exists() or (p / "AGENTS.md").is_file():
            return p
    return here


if __name__ == "__main__":
    raise SystemExit(main())
