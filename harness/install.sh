#!/usr/bin/env bash
# install.sh — Make harness scripts executable and print adoption steps for your tool.
#
# This script does two things:
#   1. chmod +x all harness/*.sh files
#   2. Add .harness/ to .gitignore (mutates the repo root .gitignore)
#   3. Print the exact copy/paste commands to adopt for your detected tool
#
# Note: step 2 modifies .gitignore at the repo root.
# Adapter adoption is copy-based — see harness/adapters/<tool>/ADAPTER.md.
#
# Usage:
#   bash harness/install.sh              # auto-detect tool
#   bash harness/install.sh cursor       # specify tool explicitly
#   bash harness/install.sh --all        # print steps for every detected tool

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
INSTALL_ALL=0
FORCE_TOOL=""

for arg in "$@"; do
  case "$arg" in
    --all)   INSTALL_ALL=1 ;;
    claude-code|copilot|cursor|windsurf|opencode|generic) FORCE_TOOL="$arg" ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

# ── 1. Make scripts executable ────────────────────────────────────────────────
find "$REPO_ROOT/harness" -name "*.sh" -exec chmod +x {} \;
echo "[HARNESS] ✓ Scripts made executable."

# ── 2. Update .gitignore ──────────────────────────────────────────────────────
GITIGNORE="$REPO_ROOT/.gitignore"
if [ -f "$GITIGNORE" ] && ! grep -q "^\.harness/" "$GITIGNORE" 2>/dev/null; then
  printf '\n# Harness runtime artifacts\n.harness/\n' >> "$GITIGNORE"
  echo "[HARNESS] ✓ Added .harness/ to .gitignore."
fi

# ── 3. Detect tools present in this repo ─────────────────────────────────────
_detect_tools() {
  local tools=()
  [ -d "$REPO_ROOT/.claude" ]                             && tools+=("claude-code")
  [ -f "$REPO_ROOT/.github/copilot-instructions.md" ]     && tools+=("copilot")
  [ -d "$REPO_ROOT/.cursor" ]                             && tools+=("cursor")
  [ -d "$REPO_ROOT/.opencode" ]                           && tools+=("opencode")
  [ -f "$REPO_ROOT/.windsurfrules" ]                      && tools+=("windsurf")
  [ ${#tools[@]} -eq 0 ]                                  && tools+=("generic")
  echo "${tools[@]}"
}

# ── 4. Print adoption steps per tool ─────────────────────────────────────────
_print_steps() {
  local tool="$1"
  echo ""
  echo "━━━ Adapter: $tool ━━━"
  echo "Docs: harness/adapters/$tool/ADAPTER.md"
  echo ""
  case "$tool" in
    claude-code)
      echo "  Merge hooks into .claude/settings.json:"
      echo "    jq -s '.[0] * .[1]' .claude/settings.json \\"
      echo "      harness/adapters/claude-code/settings.hooks.json \\"
      echo "      > .claude/settings.json.tmp \\"
      echo "      && mv .claude/settings.json.tmp .claude/settings.json"
      echo "  (or merge manually — see ADAPTER.md)"
      ;;
    copilot)
      echo "  Append governance block to .github/copilot-instructions.md:"
      echo "    cat harness/adapters/copilot/governance-block.md \\"
      echo "      >> .github/copilot-instructions.md"
      echo "  Add CI step: bash harness/adapters/generic/post-invoke.sh"
      ;;
    cursor)
      echo "  Copy rule file to .cursor/rules/:"
      echo "    mkdir -p .cursor/rules"
      echo "    cp harness/adapters/cursor/harness.mdc .cursor/rules/harness.mdc"
      ;;
    opencode)
      echo "  Copy command file to .opencode/commands/:"
      echo "    mkdir -p .opencode/commands"
      echo "    cp harness/adapters/opencode/harness.md .opencode/commands/harness.md"
      echo "  Optionally sync agents:"
      echo "    cp .claude/agents/*.md .opencode/agents/ 2>/dev/null || true"
      ;;
    windsurf)
      echo "  Copy or append to .windsurfrules:"
      echo "    cp harness/adapters/windsurf/harness-rules.md .windsurfrules"
      echo "  (or append: cat harness/adapters/windsurf/harness-rules.md >> .windsurfrules)"
      ;;
    generic)
      echo "  No tool-specific setup needed. Use the wrapper pattern:"
      echo "    eval \"\$(bash harness/adapters/generic/pre-invoke.sh)\""
      echo "    <your-agent-cli> ..."
      echo "    bash harness/adapters/generic/post-invoke.sh"
      ;;
  esac
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo ""
echo "[HARNESS] Adoption steps for this repository:"

if [ -n "$FORCE_TOOL" ]; then
  _print_steps "$FORCE_TOOL"
elif [ $INSTALL_ALL -eq 1 ]; then
  for tool in $(_detect_tools); do
    _print_steps "$tool"
  done
else
  PRIMARY=$(bash "$REPO_ROOT/harness/detect-tool.sh")
  _print_steps "$PRIMARY"
fi

echo ""
echo "[HARNESS] Quick smoke test after adoption:"
echo "  bash harness/core/gate-check.sh Bash 'git push --force'  # should block"
echo "  bash harness/core/gate-check.sh Bash 'git status'        # should approve"
echo "  eval \"\$(bash harness/bootstrap.sh)\" && echo \$HARNESS_EXECUTION_MODE"
