# Global Rules

Core rules that should apply across projects and domains.

Typical contents:

- Communication and output format norms
- Universal code quality baseline
- Security baseline (for example no secrets in code)
- Repository-agnostic safety constraints

Keep this layer stable and concise. Domain-specific or repository-specific constraints should not be stored here.

## Files

| File | Coverage |
|---|---|
| `security-baseline.md` | GSEC-001–007: secrets, injection, auth, supply chain, input validation, defaults, logging |
| `prompt-injection.md` | GSEC-PI-001: prompt injection detection and response protocol |
| `coding-discipline.md` | GCODE-001–007: assumption surfacing, minimum code, surgical changes, success criteria, autonomous loop, session hygiene, CI parity |
| `communication-baseline.md` | GCOMM-001–003: no sycophancy, never fabricate, concise by default |
