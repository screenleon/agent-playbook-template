#!/usr/bin/env bash
# detect-tool.sh — Detect which agent tool environment is active.
#
# Outputs one token to stdout:
#   claude-code | copilot | cursor | windsurf | opencode | generic
#
# Priority order: most-specific tool directory first, then fallbacks.
# A repository may contain config for multiple tools; this picks the
# environment most likely to be running the current invocation.
#
# Override via env: HARNESS_TOOL=cursor bash harness/bootstrap.sh

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

detect() {
  # Explicit override
  if [ -n "${HARNESS_TOOL:-}" ]; then
    echo "$HARNESS_TOOL"
    return
  fi

  # Claude Code: .claude/ project directory present
  if [ -d "$REPO_ROOT/.claude" ]; then
    echo "claude-code"
    return
  fi

  # Cursor: .cursor/ workspace directory present
  if [ -d "$REPO_ROOT/.cursor" ]; then
    echo "cursor"
    return
  fi

  # Windsurf: .windsurfrules file present
  if [ -f "$REPO_ROOT/.windsurfrules" ]; then
    echo "windsurf"
    return
  fi

  # OpenCode: .opencode/ directory present
  if [ -d "$REPO_ROOT/.opencode" ]; then
    echo "opencode"
    return
  fi

  # GitHub Copilot: copilot-instructions.md present (no CLI to detect)
  if [ -f "$REPO_ROOT/.github/copilot-instructions.md" ]; then
    echo "copilot"
    return
  fi

  # No specific tool detected — use generic wrapper
  echo "generic"
}

detect
