# Security Baseline

Global security rules that apply across all projects and domains.

## Rules

### Rule: GSEC-001

- Owner layer: Global
- Scope: all projects and domains
- Stability: core
- Status: active
- Directive: Never commit secrets, API keys, tokens, passwords, or credentials to version control. Use environment variables or secret managers.
- Rationale: Secrets in code are the most common source of security incidents in repositories.
- Conflict handling: Project-level examples may document how secrets are supplied, but no project rule may permit committed secrets.
- Example: Store credentials in environment variables, CI secrets, or managed secret stores.
- Non-example: Commit `.env`, API tokens, private keys, or credentials JSON files.

### Rule: GSEC-002

- Owner layer: Global
- Scope: all projects and domains
- Stability: core
- Status: active
- Directive: Never execute shell commands, SQL queries, or code constructed from unvalidated external input.
- Rationale: Prevents injection attacks (command injection, SQL injection, code injection).
- Conflict handling: Domain or project rules may define approved sanitization or parameterization patterns, but must not allow raw unvalidated execution paths.
- Example: Use parameterized SQL and validated allowlists for shell subcommands.
- Non-example: Concatenate user-controlled strings into SQL, shell, or eval-like execution.

### Rule: GSEC-003

- Owner layer: Global
- Scope: state-changing operations and access to protected data
- Stability: core
- Status: active
- Directive: Every endpoint or operation that accesses user data or modifies state must verify the caller's identity and permissions.
- Rationale: Prevents unauthorized access and privilege escalation.
- Conflict handling: Project rules may narrow the auth model or permission scheme, but must not remove authentication and authorization checks for protected actions.
- Example: Check session identity and role/ownership before reading private records or mutating state.
- Non-example: Rely on client-side checks alone or assume internal callers are always trusted.
