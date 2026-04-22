#!/usr/bin/env python3
"""
trace-query.py

Adapter-neutral analytics over `.agent-trace/*.trace.yaml`. Reads the canonical
trace schema (`docs/schemas/trace.schema.yaml`) and produces summary reports.

Any adapter that emits a conforming trace can be analyzed by this tool — the
script does not assume claude-code, copilot, or any specific runtime.

Usage:
    python3 scripts/trace-query.py --skill-hit-rate
    python3 scripts/trace-query.py --gate-activations
    python3 scripts/trace-query.py --failure-families
    python3 scripts/trace-query.py --budget-usage
    python3 scripts/trace-query.py --role-transitions
    python3 scripts/trace-query.py --summary              # everything
    python3 scripts/trace-query.py --dir custom/trace/dir
    python3 scripts/trace-query.py --format json          # JSON output

Requires only the Python standard library.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Shared zero-dep YAML parser (used by both this script and score-eval.py).
_HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE))
from trace_query_impl import parse_trace  # type: ignore  # noqa: E402

DEFAULT_TRACE_DIR = ".agent-trace"


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

def load_traces(trace_dir: Path) -> list[tuple[str, dict]]:
    traces: list[tuple[str, dict]] = []
    if not trace_dir.is_dir():
        return traces
    for path in sorted(trace_dir.iterdir()):
        if not path.name.endswith(".trace.yaml") and not path.name.endswith(".yaml"):
            continue
        if path.name.startswith("."):
            continue
        try:
            data = parse_trace(path.read_text(encoding="utf-8"))
        except Exception as exc:
            print(f"WARN: could not parse {path}: {exc}", file=sys.stderr)
            continue
        if not isinstance(data, dict):
            continue
        traces.append((path.name, data))
    return traces


# ---------------------------------------------------------------------------
# Analytics
# ---------------------------------------------------------------------------

def skill_hit_rate(traces: list[tuple[str, dict]]) -> dict:
    total = len(traces)
    counts: dict[str, int] = {}
    fail_counts: dict[str, int] = {}
    for _, t in traces:
        skills = t.get("skills_loaded") or []
        outcome = (t.get("validation_outcome") or "").lower()
        for s in skills:
            counts[s] = counts.get(s, 0) + 1
            if outcome == "fail":
                fail_counts[s] = fail_counts.get(s, 0) + 1
    table = []
    for skill, c in sorted(counts.items(), key=lambda kv: -kv[1]):
        pct = (c / total * 100.0) if total else 0.0
        table.append({
            "skill": skill,
            "load_count": c,
            "load_rate_pct": round(pct, 1),
            "fail_cooccurrence": fail_counts.get(skill, 0),
        })
    return {"traces_analyzed": total, "skills": table}


def gate_activations(traces: list[tuple[str, dict]]) -> dict:
    counts: dict[str, dict[str, int]] = {}
    for _, t in traces:
        for g in (t.get("checkpoint_gates_hit") or []):
            if not isinstance(g, dict):
                continue
            gate = g.get("gate", "unknown")
            action = g.get("action", "unknown")
            counts.setdefault(gate, {})
            counts[gate][action] = counts[gate].get(action, 0) + 1
    table = []
    for gate, actions in sorted(counts.items()):
        total = sum(actions.values())
        table.append({
            "gate": gate,
            "total": total,
            "by_action": actions,
        })
    return {"traces_analyzed": len(traces), "gates": table}


def failure_families(traces: list[tuple[str, dict]]) -> dict:
    fam_counts: dict[str, int] = {}
    repeat_counts = 0
    traces_with_retries = 0
    for _, t in traces:
        families = t.get("failure_families") or []
        if families:
            traces_with_retries += 1
        for f in families:
            if not isinstance(f, dict):
                continue
            fam = f.get("family", "unknown")
            fam_counts[fam] = fam_counts.get(fam, 0) + 1
            if f.get("same_as_previous") is True:
                repeat_counts += 1
    top = sorted(fam_counts.items(), key=lambda kv: -kv[1])
    return {
        "traces_analyzed": len(traces),
        "traces_with_retries": traces_with_retries,
        "repeated_family_hits": repeat_counts,
        "by_family": [{"family": f, "count": c} for f, c in top],
    }


def budget_usage(traces: list[tuple[str, dict]], budget_path: Path | None = None) -> dict:
    targets = _read_budget_targets(budget_path)
    buckets: dict[str, list[int]] = {
        "layer1": [], "layer2": [], "layer3": [], "layer4": [], "total": [],
    }
    profile_seen: dict[str, int] = {}
    for _, t in traces:
        b = t.get("budget")
        if not isinstance(b, dict):
            continue
        profile = b.get("profile")
        if profile:
            profile_seen[profile] = profile_seen.get(profile, 0) + 1
        for k, out in (
            ("tokens_actual_layer1", "layer1"),
            ("tokens_actual_layer2", "layer2"),
            ("tokens_actual_layer3", "layer3"),
            ("tokens_actual_layer4", "layer4"),
            ("tokens_total", "total"),
        ):
            v = b.get(k)
            if isinstance(v, int):
                buckets[out].append(v)

    def summarize(values: list[int], target: int | None) -> dict:
        if not values:
            return {"samples": 0}
        avg = sum(values) / len(values)
        peak = max(values)
        out = {"samples": len(values), "avg": round(avg, 1), "peak": peak}
        if target is not None:
            out["target"] = target
            out["over_target_count"] = sum(1 for v in values if v > target)
        return out

    return {
        "traces_analyzed": len(traces),
        "profiles_observed": profile_seen,
        "layer1": summarize(buckets["layer1"], targets.get("layer1")),
        "layer2": summarize(buckets["layer2"], targets.get("layer2")),
        "layer3": summarize(buckets["layer3"], targets.get("layer3")),
        "layer4": summarize(buckets["layer4"], None),
        "total": summarize(buckets["total"], None),
    }


def role_transitions(traces: list[tuple[str, dict]]) -> dict:
    edges: dict[tuple[str, str], int] = {}
    singletons: dict[str, int] = {}
    for _, t in traces:
        roles = t.get("roles_invoked") or []
        steps = t.get("steps") or []
        if steps:
            sequence = [s.get("role") for s in steps if isinstance(s, dict) and s.get("role")]
        else:
            sequence = list(roles)
        if len(sequence) == 1:
            singletons[sequence[0]] = singletons.get(sequence[0], 0) + 1
            continue
        for a, b in zip(sequence, sequence[1:]):
            key = (a, b)
            edges[key] = edges.get(key, 0) + 1
    table = [
        {"from": a, "to": b, "count": c}
        for (a, b), c in sorted(edges.items(), key=lambda kv: -kv[1])
    ]
    return {
        "traces_analyzed": len(traces),
        "singleton_roles": singletons,
        "transitions": table,
    }


def isolation_signal(traces: list[tuple[str, dict]]) -> dict:
    counts = {"clean": 0, "violation": 0, "relaxed": 0, "unreported": 0}
    for _, t in traces:
        status = t.get("isolation_status") or "unreported"
        if status not in counts:
            counts["unreported"] += 1
        else:
            counts[status] += 1
    return {"traces_analyzed": len(traces), "by_status": counts}


# ---------------------------------------------------------------------------
# Budget target loader — reads prompt-budget.yml:
#   layer1_target_tokens, layer2_max_tokens, layer3_max_tokens
# ---------------------------------------------------------------------------

def _find_repo_root(start: Path) -> Path | None:
    # Walk upward looking for the nearest prompt-budget.yml or .git directory.
    for p in [start, *start.parents]:
        if (p / "prompt-budget.yml").exists() or (p / ".git").exists():
            return p
    return None


def _read_budget_targets(budget_path: Path | None = None) -> dict[str, int]:
    if budget_path is None:
        root = _find_repo_root(Path.cwd())
        if root is None:
            return {}
        budget_path = root / "prompt-budget.yml"
    if not budget_path.exists():
        return {}
    text = budget_path.read_text(encoding="utf-8")
    targets: dict[str, int] = {}
    for line in text.splitlines():
        s = line.strip()
        for key, out in (
            ("layer1_target_tokens", "layer1"),
            ("layer2_max_tokens", "layer2"),
            ("layer3_max_tokens", "layer3"),
        ):
            if s.startswith(key + ":"):
                try:
                    val = int(s.split(":", 1)[1].split("#", 1)[0].strip())
                    targets[out] = val
                except ValueError:
                    pass
    return targets


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def render_table(data: dict) -> str:
    lines: list[str] = []
    for k, v in data.items():
        if isinstance(v, (int, float, str)) or v is None:
            lines.append(f"{k}: {v}")
        elif isinstance(v, dict):
            lines.append(f"{k}:")
            for k2, v2 in v.items():
                lines.append(f"  {k2}: {v2}")
        elif isinstance(v, list):
            lines.append(f"{k}: ({len(v)} entries)")
            for item in v[:25]:
                if isinstance(item, dict):
                    bits = ", ".join(f"{a}={b}" for a, b in item.items())
                    lines.append(f"  - {bits}")
                else:
                    lines.append(f"  - {item}")
            if len(v) > 25:
                lines.append(f"  ... ({len(v) - 25} more)")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description="Adapter-neutral trace analytics")
    ap.add_argument("--dir", default=DEFAULT_TRACE_DIR, help="Trace directory (default: .agent-trace)")
    ap.add_argument("--budget-file", default=None,
                    help="Path to prompt-budget.yml (default: auto-detect repo root)")
    ap.add_argument("--skill-hit-rate", action="store_true")
    ap.add_argument("--gate-activations", action="store_true")
    ap.add_argument("--failure-families", action="store_true")
    ap.add_argument("--budget-usage", action="store_true")
    ap.add_argument("--role-transitions", action="store_true")
    ap.add_argument("--isolation", action="store_true")
    ap.add_argument("--summary", action="store_true", help="Run all analyses")
    ap.add_argument("--format", choices=["table", "json"], default="table")
    args = ap.parse_args()

    traces = load_traces(Path(args.dir))
    if not traces:
        print(f"No traces found in {args.dir}", file=sys.stderr)
        return 2

    reports: dict[str, dict] = {}
    if args.summary or args.skill_hit_rate:
        reports["skill_hit_rate"] = skill_hit_rate(traces)
    if args.summary or args.gate_activations:
        reports["gate_activations"] = gate_activations(traces)
    if args.summary or args.failure_families:
        reports["failure_families"] = failure_families(traces)
    if args.summary or args.budget_usage:
        budget_path = Path(args.budget_file) if args.budget_file else None
        reports["budget_usage"] = budget_usage(traces, budget_path)
    if args.summary or args.role_transitions:
        reports["role_transitions"] = role_transitions(traces)
    if args.summary or args.isolation:
        reports["isolation"] = isolation_signal(traces)

    if not reports:
        ap.print_help()
        return 1

    if args.format == "json":
        print(json.dumps(reports, indent=2, sort_keys=False))
    else:
        for name, data in reports.items():
            print(f"\n== {name} ==")
            print(render_table(data))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
