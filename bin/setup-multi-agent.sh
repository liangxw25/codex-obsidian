#!/usr/bin/env bash
# codex-obsidian skill installer
# Symlinks this repository's skills/ directory into Codex and installs
# project-local Codex hooks for a vault directory.
#
# Usage:
#   bash bin/setup-multi-agent.sh [optional: /path/to/vault]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
HOOKS_DIR="$REPO_ROOT/hooks"
VAULT_DIR="${1:-$REPO_ROOT}"
VAULT_DIR="$(mkdir -p "$VAULT_DIR" && cd "$VAULT_DIR" && pwd)"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "ERROR: $SKILLS_DIR does not exist. Are you running this from codex-obsidian?" >&2
  exit 1
fi

if [ ! -x "$HOOKS_DIR/post-tool-use-auto-commit.sh" ] || [ ! -x "$HOOKS_DIR/session-start-hot-cache.sh" ]; then
  echo "ERROR: hook scripts are missing or not executable in $HOOKS_DIR" >&2
  exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;37m'
NC='\033[0m'

link_if_missing() {
  local target="$1"
  local dest="$2"
  local agent_name="$3"

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    local existing
    existing="$(readlink "$dest")"
    if [ "$existing" = "$target" ]; then
      echo -e "${GRAY}[$agent_name] already linked: $dest${NC}"
      return
    fi
    echo -e "${YELLOW}[$agent_name] symlink exists but points elsewhere: $dest -> $existing (skipping)${NC}"
    return
  fi

  if [ -e "$dest" ]; then
    echo -e "${YELLOW}[$agent_name] path exists and is not a symlink: $dest (skipping)${NC}"
    return
  fi

  ln -s "$target" "$dest"
  echo -e "${GREEN}[$agent_name] linked: $dest -> $target${NC}"
}

install_codex_hooks() {
  local vault="$1"
  local hooks_file="$vault/.codex/hooks.json"

  mkdir -p "$(dirname "$hooks_file")"

  if [ -e "$hooks_file" ]; then
    if grep -q "codex-obsidian" "$hooks_file" 2>/dev/null; then
      echo -e "${GRAY}[Codex] hooks already configured: $hooks_file${NC}"
    else
      echo -e "${YELLOW}[Codex] hooks file exists and was not modified: $hooks_file${NC}"
      echo -e "${YELLOW}        Add hooks from $REPO_ROOT/.codex/hooks.json manually if this vault should auto-commit wiki changes.${NC}"
    fi
    return
  fi

  cat > "$hooks_file" <<JSON
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "CODEX_OBSIDIAN_HOME='$REPO_ROOT' '$REPO_ROOT/hooks/session-start-hot-cache.sh'",
            "statusMessage": "Loading codex-obsidian hot cache",
            "timeout": 30
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|apply_patch",
        "hooks": [
          {
            "type": "command",
            "command": "CODEX_OBSIDIAN_HOME='$REPO_ROOT' '$REPO_ROOT/hooks/post-tool-use-auto-commit.sh'",
            "statusMessage": "Auto-committing codex-obsidian wiki changes",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
JSON
  echo -e "${GREEN}[Codex] hooks installed: $hooks_file${NC}"
}

echo "codex-obsidian: skill installer"
echo "Repo: $REPO_ROOT"
echo "Vault: $VAULT_DIR"
echo

link_if_missing "$SKILLS_DIR" "$HOME/.codex/skills/codex-obsidian" "Codex"

if [ "${CODEX_OBSIDIAN_INSTALL_HOOKS:-1}" = "1" ]; then
  install_codex_hooks "$VAULT_DIR"
else
  echo -e "${GRAY}[Codex] hooks skipped because CODEX_OBSIDIAN_INSTALL_HOOKS=0${NC}"
fi

if [ "${CODEX_OBSIDIAN_INSTALL_EXTRAS:-0}" = "1" ]; then
  link_if_missing "$SKILLS_DIR" "$HOME/.opencode/skills/codex-obsidian" "OpenCode"
  link_if_missing "$SKILLS_DIR" "$HOME/.gemini/skills/codex-obsidian" "Gemini"
fi

echo
echo -e "${GREEN}Done.${NC}"
echo "Verify in Codex by asking what skills are available, or by triggering /wiki."
echo "Codex may ask you to trust project hooks the next time you start a session in this vault."
echo "Set CODEX_OBSIDIAN_INSTALL_EXTRAS=1 to also link OpenCode and Gemini skill directories."
