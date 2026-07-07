#!/usr/bin/env bash
# Auto-commit codex-obsidian runtime wiki changes after Codex write tools.
# The commit scope is restricted to wiki/, .raw/, and .vault-meta/.

set -u

detect_git_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

VAULT_ROOT="${CODEX_OBSIDIAN_VAULT:-$(detect_git_root)}"
TOOL_ROOT="${CODEX_OBSIDIAN_HOME:-$VAULT_ROOT}"

cd "$VAULT_ROOT" 2>/dev/null || exit 0

[ -d .git ] || exit 0
[ -d wiki ] || exit 0
[ "${CODEX_OBSIDIAN_AUTO_COMMIT:-1}" = "1" ] || exit 0
[ -f .vault-meta/auto-commit.disabled ] && exit 0

log_hook() {
  mkdir -p .vault-meta 2>/dev/null || true
  printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%SZ')" "$*" >> .vault-meta/hook.log 2>/dev/null || true
}

LOCK_SCRIPT=""
if [ -x "$VAULT_ROOT/scripts/wiki-lock.sh" ]; then
  LOCK_SCRIPT="$VAULT_ROOT/scripts/wiki-lock.sh"
elif [ -x "$TOOL_ROOT/scripts/wiki-lock.sh" ]; then
  LOCK_SCRIPT="$TOOL_ROOT/scripts/wiki-lock.sh"
fi

if [ -n "$LOCK_SCRIPT" ]; then
  LOCK_LIST="$(WIKI_LOCK_VAULT="$VAULT_ROOT" bash "$LOCK_SCRIPT" list 2>/dev/null)"
  LOCK_RC=$?
  if [ "$LOCK_RC" != "0" ]; then
    log_hook "wiki-lock list failed rc=$LOCK_RC; deferred auto-commit"
    exit 0
  fi
  if [ -n "$LOCK_LIST" ]; then
    exit 0
  fi
fi

TMP="$(mktemp "${TMPDIR:-/tmp}/codex-obsidian-hook.XXXXXX")" || exit 0
STAGED_TMP="$(mktemp "${TMPDIR:-/tmp}/codex-obsidian-hook-staged.XXXXXX")" || exit 0
trap 'rm -f "$TMP" "$STAGED_TMP"' EXIT

EXCLUDES=(
  ':(exclude).vault-meta/.address.lock'
  ':(exclude).vault-meta/.tiling.lock'
  ':(exclude).vault-meta/.wiki-lock.meta'
  ':(exclude).vault-meta/.bm25.lock'
  ':(exclude).vault-meta/.embed-cache.lock'
  ':(exclude).vault-meta/locks/*'
  ':(exclude).vault-meta/chunks/*'
  ':(exclude).vault-meta/bm25/*'
  ':(exclude).vault-meta/embed-cache.json'
  ':(exclude).vault-meta/embed-cache.*.tmp'
  ':(exclude).vault-meta/tiling-cache.json'
  ':(exclude).vault-meta/tiling-cache.*.tmp'
  ':(exclude).vault-meta/transport.json'
  ':(exclude).vault-meta/transport.*.tmp'
  ':(exclude).vault-meta/hook.log'
)

git diff --name-only -z -- wiki .raw .vault-meta "${EXCLUDES[@]}" > "$TMP" 2>/dev/null || true
git ls-files --others --exclude-standard -z -- wiki .raw .vault-meta "${EXCLUDES[@]}" >> "$TMP" 2>/dev/null || true

if [ -s "$TMP" ]; then
  xargs -0 git add -- < "$TMP" 2>/dev/null || {
    log_hook "git add failed; deferred auto-commit"
    exit 0
  }
fi

if git diff --cached --quiet -- wiki .raw .vault-meta "${EXCLUDES[@]}" 2>/dev/null; then
  exit 0
fi

git diff --cached --name-only -z -- wiki .raw .vault-meta "${EXCLUDES[@]}" > "$STAGED_TMP" 2>/dev/null || true
if [ ! -s "$STAGED_TMP" ]; then
  exit 0
fi

xargs -0 git commit -m "wiki: auto-commit $(date '+%Y-%m-%d %H:%M')" -- < "$STAGED_TMP" >/dev/null 2>&1 || true
