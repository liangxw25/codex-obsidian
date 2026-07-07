#!/usr/bin/env bash
# Load codex-obsidian hot cache into a new/resumed Codex session.
# Safe in non-vault directories: exits 0 and prints nothing when no hot cache exists.

set -u

detect_git_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

VAULT_ROOT="${CODEX_OBSIDIAN_VAULT:-$(detect_git_root)}"
TOOL_ROOT="${CODEX_OBSIDIAN_HOME:-$VAULT_ROOT}"

LOCK_SCRIPT=""
if [ -x "$VAULT_ROOT/scripts/wiki-lock.sh" ]; then
  LOCK_SCRIPT="$VAULT_ROOT/scripts/wiki-lock.sh"
elif [ -x "$TOOL_ROOT/scripts/wiki-lock.sh" ]; then
  LOCK_SCRIPT="$TOOL_ROOT/scripts/wiki-lock.sh"
fi

if [ -n "$LOCK_SCRIPT" ]; then
  WIKI_LOCK_VAULT="$VAULT_ROOT" bash "$LOCK_SCRIPT" clear-stale --max-age 3600 >/dev/null 2>&1 || true
fi

HOT="$VAULT_ROOT/wiki/hot.md"
if [ -f "$HOT" ]; then
  echo "codex-obsidian hot cache: $HOT"
  echo
  sed -n '1,220p' "$HOT"
fi
