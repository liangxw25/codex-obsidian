#!/usr/bin/env bash
# test_hooks.sh — validate Codex hook config and auto-commit behavior.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POST_HOOK="$ROOT/hooks/post-tool-use-auto-commit.sh"
SESSION_HOOK="$ROOT/hooks/session-start-hot-cache.sh"

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "OK   $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL $label: expected '$expected', got '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

assert_true() {
  local label="$1"
  shift
  if "$@"; then
    echo "OK   $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL $label"
    FAIL=$((FAIL + 1))
  fi
}

make_vault() {
  local dir
  dir="$(mktemp -d /tmp/codex-obsidian-hooks-XXXXXX)"
  mkdir -p "$dir/wiki" "$dir/.raw" "$dir/.vault-meta/locks"
  cat > "$dir/wiki/hot.md" <<'MD'
# 热缓存

## 最近状态

hook test seed
MD
  cp "$ROOT/templates/vault.gitignore" "$dir/.gitignore"
  (
    cd "$dir" || exit 1
    git init -q
    git config user.email "test@example.com"
    git config user.name "codex-obsidian test"
    git add .gitignore wiki .raw .vault-meta
    git commit -q -m "initial vault"
  )
  echo "$dir"
}

SANDBOXES=()
cleanup() {
  for dir in "${SANDBOXES[@]}"; do
    rm -rf "$dir"
  done
}
trap cleanup EXIT

echo "=== test_hooks.sh ==="
echo ""

python3 -m json.tool "$ROOT/.codex/hooks.json" >/dev/null
assert_eq "Codex hooks JSON parses" "0" "$?"
assert_true "PostToolUse hook executable" test -x "$POST_HOOK"
assert_true "SessionStart hook executable" test -x "$SESSION_HOOK"

VAULT="$(make_vault)"
SANDBOXES+=("$VAULT")
echo "new fact" >> "$VAULT/wiki/hot.md"
(
  cd "$VAULT" || exit 1
  CODEX_OBSIDIAN_HOME="$ROOT" "$POST_HOOK"
)
LAST_MSG="$(git -C "$VAULT" log -1 --pretty=%s)"
case "$LAST_MSG" in
  "wiki: auto-commit "*) assert_eq "PostToolUse auto-commits wiki change" "yes" "yes" ;;
  *) assert_eq "PostToolUse auto-commits wiki change" "yes" "no($LAST_MSG)" ;;
esac
STATUS="$(git -C "$VAULT" status --short -- wiki .raw .vault-meta)"
assert_eq "runtime paths clean after auto-commit" "" "$STATUS"

IGNORED="$(mktemp -d /tmp/codex-obsidian-hooks-ignored-XXXXXX)"
SANDBOXES+=("$IGNORED")
(
  cd "$IGNORED" || exit 1
  git init -q
  git config user.email "test@example.com"
  git config user.name "codex-obsidian test"
  cat > .gitignore <<'GITIGNORE'
/wiki/
/.raw/
/.vault-meta/
GITIGNORE
  mkdir -p wiki .raw .vault-meta/locks
  echo "# ignored hot" > wiki/hot.md
  CODEX_OBSIDIAN_HOME="$ROOT" "$POST_HOOK"
  git rev-parse --verify HEAD >/dev/null 2>&1
)
assert_eq "ignored runtime dirs do not create a commit" "128" "$?"

SESSION_OUT="$(
  cd "$VAULT" || exit 1
  CODEX_OBSIDIAN_HOME="$ROOT" "$SESSION_HOOK"
)"
case "$SESSION_OUT" in
  *"hook test seed"* | *"new fact"*) assert_eq "SessionStart emits hot cache" "yes" "yes" ;;
  *) assert_eq "SessionStart emits hot cache" "yes" "no" ;;
esac

echo ""
echo "Pass: $PASS  Fail: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All hook tests passed."
