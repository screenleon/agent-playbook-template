# context-pack-determinism

Verifies that `scripts/build-context-pack.py` produces byte-identical output
for identical inputs, and that the output matches the checked-in golden
file (`expected.json`).

## What this catches

- Accidental use of `time.time()` or other non-deterministic sources.
- Dict key ordering drift from hash-randomized iteration.
- Unsorted list outputs.
- Changes to selection/ranking logic that silently alter ordering.

## Running

```bash
bash scripts/test-tooling.sh context-pack-determinism
```

## Regenerating the golden file

When a deliberate change to the builder output is made, regenerate with:

```bash
bash evals/tooling/context-pack-determinism/regenerate.sh
```

Review the resulting diff carefully before committing — a change to the
golden file is a change to the context-pack contract.
