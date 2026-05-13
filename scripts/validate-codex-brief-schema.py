#!/usr/bin/env python3
"""Narrow structural linter for codex-brief YAML files.
Validates that required top-level fields, array bounds, enum values, and
required scalar string values declared in docs/schemas/codex-brief.schema.yaml
are present and correct.
Standard-library only — no third-party dependencies.

Scope: structural and value linting for well-formed YAML briefs.
       Enforces: required top-level fields, non-empty/non-null required
       string scalars (working_dir, goal, files[].path), array minItems,
       and files[].action enum values.
       Out of scope: YAML syntax errors (unclosed brackets, mismatched
       quotes, etc.) that still include valid column-0 key: value structure
       are not detected — use a full YAML parser for syntax validation.
       Structurally malformed documents with no column-0 key: value pairs
       at all are detected as invalid.
"""
import sys
import os
import re

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURE_DIR = os.path.join(REPO_ROOT, "evals/tooling/codex-brief-schema-validation")

REQUIRED_TOP_LEVEL = ["working_dir", "goal", "files", "acceptance", "self_verify"]
VALID_ACTIONS = {"read", "write", "new", "edit"}


def _non_empty(value: str) -> bool:
    """Return True only when a YAML scalar value is a present, non-null, non-empty string."""
    s = value.strip()
    return s != "" and s.lower() != "null"


def _list_item_count(text: str, key: str) -> int:
    """Count top-level list items under `key:` in YAML text."""
    m = re.search(rf'^{re.escape(key)}:\s*\n((?:[ \t]+.*\n?)*)', text, re.MULTILINE)
    if not m:
        return 0
    return len(re.findall(r'^\s+-', m.group(1), re.MULTILINE))


def _files_section(text: str) -> str:
    m = re.search(r'^files:\s*\n((?:[ \t]+.*\n?)*)', text, re.MULTILINE)
    return m.group(1) if m else ""


def validate_brief(text: str) -> list:
    errors = []

    # Structural sanity: document must have at least one top-level `key: value`
    # line (i.e. a key at column 0 followed by a colon). Indented-only or
    # gibberish documents lack this and are treated as malformed.
    if not re.search(r'^[a-zA-Z_][a-zA-Z0-9_]*\s*:', text, re.MULTILINE):
        return ["malformed YAML: no top-level key: value pair found at column 0"]

    # Required top-level fields — must be present AND non-empty for scalar fields
    SCALAR_FIELDS = {"working_dir", "goal"}
    for key in REQUIRED_TOP_LEVEL:
        m = re.search(rf'^{re.escape(key)}\s*:(.*)', text, re.MULTILINE)
        if not m:
            errors.append(f"missing required field: '{key}'")
        elif key in SCALAR_FIELDS and not _non_empty(m.group(1)):
            errors.append(f"'{key}' must have a non-empty, non-null string value")

    # files.minItems: 1
    if re.search(r'^files\s*:', text, re.MULTILINE) and _list_item_count(text, "files") == 0:
        errors.append("files: must have at least one item (minItems: 1)")

    # acceptance.minItems: 1
    if re.search(r'^acceptance\s*:', text, re.MULTILINE) and _list_item_count(text, "acceptance") == 0:
        errors.append("acceptance: must have at least one item (minItems: 1)")

    # self_verify.minItems: 1
    if re.search(r'^self_verify\s*:', text, re.MULTILINE) and _list_item_count(text, "self_verify") == 0:
        errors.append("self_verify: must have at least one item (minItems: 1)")

    # files[].action required and files[].path required
    section = _files_section(text)
    if section:
        boundaries = [m.start() for m in re.finditer(r'^\s+-', section, re.MULTILINE)]
        boundaries.append(len(section))
        for i in range(len(boundaries) - 1):
            item = section[boundaries[i]:boundaries[i + 1]]
            # action required
            action_m = re.search(r'(?:^|\s)action:\s*(\S+)', item)
            if not action_m:
                errors.append(f"files[{i}]: missing required field 'action'")
            elif action_m.group(1) not in VALID_ACTIONS:
                errors.append(
                    f"files[{i}].action '{action_m.group(1)}' not in enum {sorted(VALID_ACTIONS)}"
                )
            # path required and non-empty
            path_m = re.search(r'path:\s*(.*)', item)
            if not path_m:
                errors.append(f"files[{i}]: missing required field 'path'")
            elif not _non_empty(path_m.group(1)):
                errors.append(f"files[{i}].path must have a non-empty, non-null string value")

    return errors


def main():
    cases = [
        ("valid_brief.yaml",              False),
        ("invalid_missing_goal.yaml",     True),
        ("invalid_bad_action.yaml",       True),
        ("invalid_empty_arrays.yaml",     True),
        ("invalid_missing_path.yaml",     True),
        ("invalid_missing_action.yaml",   True),
        ("invalid_malformed.yaml",        True),
        ("invalid_empty_scalars.yaml",    True),
        ("invalid_null_scalars.yaml",     True),
        ("invalid_empty_path.yaml",       True),
    ]

    passed = 0
    failed = 0
    for filename, expect_errors in cases:
        path = os.path.join(FIXTURE_DIR, filename)
        with open(path) as f:
            text = f.read()
        errors = validate_brief(text)
        if expect_errors and not errors:
            print(f"FAIL [{filename}]: expected validation errors, got none", file=sys.stderr)
            failed += 1
        elif not expect_errors and errors:
            print(f"FAIL [{filename}]: expected no errors, got: {errors}", file=sys.stderr)
            failed += 1
        else:
            label = f"caught: {errors}" if errors else "clean"
            print(f"PASS [{filename}]: {label}")
            passed += 1

    print(f"Schema validation: {passed}/{passed + failed} passed")
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
