# Security Baseline

Global security rules that apply across all projects and domains.

## Rules

### GSEC-001: No secrets in code

- Rule ID: GSEC-001
- Layer: Global
- Stability: core
- Description: Never commit secrets, API keys, tokens, passwords, or credentials to version control. Use environment variables or secret managers.
- Rationale: Secrets in code are the most common source of security incidents in repositories.

### GSEC-002: No unvalidated external input execution

- Rule ID: GSEC-002
- Layer: Global
- Stability: core
- Description: Never execute shell commands, SQL queries, or code constructed from unvalidated external input.
- Rationale: Prevents injection attacks (command injection, SQL injection, code injection).

### GSEC-003: Require authentication and authorization checks

- Rule ID: GSEC-003
- Layer: Global
- Stability: core
- Description: Every endpoint or operation that accesses user data or modifies state must verify the caller's identity and permissions.
- Rationale: Prevents unauthorized access and privilege escalation.
