---
name: mcp-validation
description: Use to verify MCP tool server availability before relying on external tools, and to manage fallback strategies when tools are unavailable.
---

# MCP Dynamic Validation

Use this skill to catch tool-server mismatches early, before they cause silent failures during task execution.

## Agent-deference notice

Many agent platforms (e.g., VS Code Copilot, Claude with tool routing) already handle MCP tool availability checks natively. **If your agent platform provides built-in MCP error handling**, mark this skill as `[AGENT-NATIVE]` in `prompt-budget.yml` and skip it. See `docs/operating-rules.md` → Agent-deference principle.

## Activation condition

This skill activates only when `project/project-manifest.md` contains a `## MCP tool declarations` section with at least one declared tool. If the section is empty or absent, this skill short-circuits — no action needed.

## Pre-flight check procedure

Run this check at the start of every task that may use MCP tools. For Small tasks with no expected MCP tool usage, skip this check.

### Step 1: Enumerate declared tools

Read `project/project-manifest.md` → `MCP tool declarations`. Collect the list of declared tool names and their fallback mappings.

### Step 2: Probe each tool

For each declared tool, attempt a minimal no-op invocation (e.g., list capabilities, ping, or a read-only query that produces negligible side effects). Record:

- **Available**: tool responded successfully
- **Unavailable**: tool timed out, returned an error, or is not registered
- **Degraded**: tool responded but with warnings or partial capability

### Step 3: Report availability

Produce an availability summary before proceeding with the task:

```text
**MCP tool availability**:
- tool-a: available
- tool-b: unavailable → fallback: built-in-equivalent-b
- tool-c: degraded (read-only mode)
```

If all tools are available, proceed normally. If any tool is unavailable or degraded, apply the fallback strategy below.

## Fallback strategy

When a declared MCP tool is unavailable:

1. **Check fallback mapping** — look up the `fallback_builtin` column in the MCP tool declarations table.
2. **Use the fallback** — if a built-in equivalent exists, use it and log the substitution in the handoff artifact or task summary:
   ```text
   **Tool substitution**: tool-b unavailable → using built-in-equivalent-b
   ```
3. **No fallback available** — if no built-in equivalent is declared, report the gap to the user and ask whether to proceed without that capability or wait for the tool to become available.
4. **Never silently skip** — do not proceed as if the tool call succeeded when it failed. Always log the substitution or the gap.

## Periodic revalidation

During long-running tasks (Medium/Large scale), tool availability may change. Revalidate when:

- A **role transition** occurs (each new role re-checks before starting work)
- The task exceeds **10 tool calls** since the last validation
- A tool call **fails unexpectedly** mid-task (trigger immediate revalidation of all declared tools)

## Integration with handoff artifacts

When MCP tool substitutions occur during a task, include them in the handoff artifact:

- In the text template: add a `- **Tool substitutions**: [list]` line
- In the structured schema: substitutions can be recorded in the `open_risks` array with severity `low`, or as a note in `deliverable_summary`

## MCP tool declarations format

Declare MCP tools in `project/project-manifest.md` → `## MCP tool declarations`:

```markdown
| Tool name | Server / endpoint | Fallback builtin | Notes |
|---|---|---|---|
| mcp_github_create_issue | github MCP server | — | Required for issue automation |
| mcp_figma_get_design_context | figma MCP server | — | Optional, design-to-code only |
```

If no MCP tools are used, leave the table empty or omit the section entirely.
