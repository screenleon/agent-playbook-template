# Domain Template: Cloud Infrastructure Rules

Use this template for cloud infrastructure constraints reusable across repositories.

## Rule entries

Repeat this block for each rule.

```markdown
### Rule: <RULE_ID>
- Owner layer: Domain
- Domain: cloud-infra
- Stability: <core | behavior | experimental>
- Status: active
- Scope: <module or surface>
- Directive: <clear non-negotiable rule>
- Rationale: <why>
- Conflict handling: <what overrides this rule or when to escalate>
- Example: <positive example>
- Non-example: <what this rule forbids or does not cover>
- Supersedes: <RULE_ID or N/A>
- Superseded by: <RULE_ID or N/A>
```

## Starter examples

### Rule: INFRA-001

- Owner layer: Domain
- Domain: cloud-infra
- Stability: core
- Status: active
- Scope: infrastructure as code
- Directive: All infrastructure changes must go through version-controlled IaC files.
- Rationale: Repeatability and auditability.
- Conflict handling: Emergency manual changes must be backfilled into IaC and reviewed; project rules may define the emergency window.
- Example: Add a queue, policy, or database setting through Terraform/CDK and review the generated plan.
- Non-example: Change a production security group in the console and leave the repository unchanged.
- Supersedes: N/A
- Superseded by: N/A

### Rule: INFRA-002

- Owner layer: Domain
- Domain: cloud-infra
- Stability: core
- Status: active
- Scope: secret management
- Directive: Runtime secrets must come from managed secret stores; never from committed files.
- Rationale: Security and compliance.
- Conflict handling: Local development examples may use placeholder values, but real credentials must stay in managed stores or local ignored files.
- Example: Configure production credentials through a cloud secret manager or CI secret.
- Non-example: Commit a `.env` file with real API keys for deployment convenience.
- Supersedes: N/A
- Superseded by: N/A
