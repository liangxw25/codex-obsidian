# codex-obsidian Hooks

Codex hooks keep the vault loop closed:

| Event | Purpose |
|---|---|
| `SessionStart` | Reads `wiki/hot.md` into a fresh or resumed Codex session and clears stale wiki locks. |
| `PostToolUse` | After `Edit`, `Write`, or `apply_patch`, commits changed `wiki/`, `.raw/`, and `.vault-meta/` files when no wiki locks are active. |

The active Codex configuration lives in `.codex/hooks.json`. `bin/setup-multi-agent.sh` can also write an equivalent `.codex/hooks.json` into a separate vault directory:

```bash
bash bin/setup-multi-agent.sh /path/to/ExistingVault
```

Auto-commit is deliberately scoped to runtime vault paths and uses Git pathspecs so pre-staged files outside the vault are not swept into `wiki: auto-commit ...` commits.

Disable auto-commit for a vault by creating:

```text
.vault-meta/auto-commit.disabled
```

Set `CODEX_OBSIDIAN_AUTO_COMMIT=0` for a single Codex process when you need temporary manual control.
