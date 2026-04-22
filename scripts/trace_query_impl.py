"""
trace_query_impl.py — Shared zero-dep YAML parser for trace & expected-behavior files.

Intentionally a subset of YAML, tuned for the structures declared in
`docs/schemas/trace.schema.yaml` and `evals/schema/expected-behavior.schema.yaml`.

Public surface:
    parse_trace(text: str) -> dict
"""

from __future__ import annotations

import re
from typing import Any

_SCALAR_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$")
_LIST_ITEM_RE = re.compile(r"^-\s*(.*)$")


def _strip_inline_comment(value: str) -> str:
    if value.startswith('"') or value.startswith("'"):
        return value
    return re.sub(r"\s+#.*$", "", value)


def _coerce_scalar(raw: str) -> Any:
    s = raw.strip()
    if s == "":
        return None
    if s in ("~", "null", "Null", "NULL"):
        return None
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        return s[1:-1]
    if s.lower() in ("true", "false"):
        return s.lower() == "true"
    if re.fullmatch(r"-?\d+", s):
        return int(s)
    if re.fullmatch(r"-?\d+\.\d+", s):
        return float(s)
    # Inline flow-style empty containers.
    if s == "[]":
        return []
    if s == "{}":
        return {}
    # Inline flow-style list `[a, b, c]` — strings only, no nested structures.
    m = re.fullmatch(r"\[\s*(.*?)\s*\]", s)
    if m:
        body = m.group(1)
        if body == "":
            return []
        parts = [p.strip() for p in body.split(",")]
        return [_coerce_scalar(p) for p in parts]
    # Strip block-scalar indicators so multi-line strings don't confuse callers.
    if s in ("|", ">", "|-", ">-", "|+", ">+"):
        return ""
    return s


def _line_indent(s: str) -> int:
    return len(s) - len(s.lstrip(" "))


class TraceParseError(ValueError):
    """Raised for input the subset-YAML parser cannot safely handle."""


def _check_no_tab_indent(lines: list[str]) -> None:
    # Tab indentation is ambiguous under an indent-based parser. Fail fast
    # rather than silently misreading nested blocks.
    for idx, raw in enumerate(lines, start=1):
        if raw and raw[0] == "\t":
            raise TraceParseError(
                f"line {idx}: tab indentation is not supported; use spaces"
            )
        stripped = raw.lstrip(" ")
        if stripped and stripped[0] == "\t":
            raise TraceParseError(
                f"line {idx}: mixed space+tab indentation is not supported"
            )


def parse_trace(text: str) -> dict:
    """Parse a trace / expected-behavior YAML file into a dict.

    Raises TraceParseError when the input uses tab indentation (ambiguous
    under this indent-based parser).
    """
    lines = text.splitlines()
    _check_no_tab_indent(lines)
    root: dict = {}
    i = 0
    n = len(lines)

    while i < n:
        raw = lines[i]
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue
        if _line_indent(raw) != 0:
            i += 1
            continue
        m = _SCALAR_RE.match(stripped)
        if not m:
            i += 1
            continue
        key, rest = m.group(1), _strip_inline_comment(m.group(2).strip())

        if rest != "":
            # Multi-line block scalar (| or >) — capture following lines.
            if rest in ("|", ">", "|-", ">-", "|+", ">+"):
                block_lines, j = _consume_block_scalar(lines, i + 1)
                root[key] = "\n".join(block_lines)
                i = j
                continue
            root[key] = _coerce_scalar(rest)
            i += 1
            continue

        j = i + 1
        while j < n and (lines[j].strip() == "" or lines[j].strip().startswith("#")):
            j += 1
        if j >= n:
            root[key] = None
            break

        peek = lines[j]
        peek_indent = _line_indent(peek)
        peek_stripped = peek.strip()

        if peek_indent == 0:
            root[key] = None
            i = j
            continue
        if peek_stripped.startswith("- "):
            items, i = _parse_list(lines, j, peek_indent)
            root[key] = items
        else:
            obj, i = _parse_block(lines, j, peek_indent)
            root[key] = obj
    return root


def _consume_block_scalar(lines: list[str], start: int) -> tuple[list[str], int]:
    """Consume indented lines that belong to a `|`- or `>`-style block scalar."""
    collected: list[str] = []
    i = start
    n = len(lines)
    base_indent: int | None = None
    while i < n:
        raw = lines[i]
        if raw.strip() == "":
            collected.append("")
            i += 1
            continue
        ind = _line_indent(raw)
        if base_indent is None:
            if ind == 0:
                break
            base_indent = ind
        if ind < (base_indent or 0):
            break
        collected.append(raw[base_indent:] if base_indent else raw)
        i += 1
    return collected, i


def _parse_block(lines: list[str], start: int, indent: int) -> tuple[dict, int]:
    obj: dict = {}
    i = start
    n = len(lines)
    while i < n:
        raw = lines[i]
        stripped = raw.strip()
        if stripped == "" or stripped.startswith("#"):
            i += 1
            continue
        cur_indent = _line_indent(raw)
        if cur_indent < indent:
            break
        if cur_indent > indent:
            i += 1
            continue
        m = _SCALAR_RE.match(stripped)
        if not m:
            break
        key, rest = m.group(1), _strip_inline_comment(m.group(2).strip())

        if rest != "":
            if rest in ("|", ">", "|-", ">-", "|+", ">+"):
                block_lines, i = _consume_block_scalar(lines, i + 1)
                obj[key] = "\n".join(block_lines)
                continue
            obj[key] = _coerce_scalar(rest)
            i += 1
            continue

        j = i + 1
        while j < n and (lines[j].strip() == "" or lines[j].strip().startswith("#")):
            j += 1
        if j >= n:
            obj[key] = None
            break
        peek = lines[j]
        peek_indent = _line_indent(peek)
        if peek_indent <= indent:
            obj[key] = None
            i = j
            continue
        if peek.strip().startswith("- "):
            items, i = _parse_list(lines, j, peek_indent)
            obj[key] = items
        else:
            sub, i = _parse_block(lines, j, peek_indent)
            obj[key] = sub
    return obj, i


def _parse_list(lines: list[str], start: int, indent: int) -> tuple[list, int]:
    items: list = []
    i = start
    n = len(lines)
    while i < n:
        raw = lines[i]
        stripped = raw.strip()
        if stripped == "" or stripped.startswith("#"):
            i += 1
            continue
        cur_indent = _line_indent(raw)
        if cur_indent < indent:
            break
        if cur_indent > indent:
            i += 1
            continue
        mi = _LIST_ITEM_RE.match(stripped)
        if not mi:
            break
        body = mi.group(1).strip()

        mkv = _SCALAR_RE.match(body)
        if mkv and mkv.group(2).strip() != "":
            obj: dict = {mkv.group(1): _coerce_scalar(_strip_inline_comment(mkv.group(2).strip()))}
            i += 1
            while i < n:
                raw2 = lines[i]
                s2 = raw2.strip()
                if s2 == "" or s2.startswith("#"):
                    i += 1
                    continue
                ind2 = _line_indent(raw2)
                if ind2 <= indent:
                    break
                mk = _SCALAR_RE.match(s2)
                if not mk:
                    break
                k, v = mk.group(1), _strip_inline_comment(mk.group(2).strip())
                obj[k] = _coerce_scalar(v) if v != "" else None
                i += 1
            items.append(obj)
            continue

        if body == "":
            i += 1
            if i < n:
                next_raw = lines[i]
                next_indent = _line_indent(next_raw)
                if next_indent > indent:
                    sub, i = _parse_block(lines, i, next_indent)
                    items.append(sub)
                    continue
            items.append({})
            continue

        items.append(_coerce_scalar(body))
        i += 1
    return items, i
