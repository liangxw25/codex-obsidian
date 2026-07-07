# Git Setup

Initialize git in the vault to get full history and protect against bad writes.

---

## Initialize

```bash
cd "$VAULT_PATH"
git init
git add -A
git commit -m "Initial vault scaffold"
```

---

## .gitignore

For a personal vault, track `wiki/`, `.raw/`, and `.vault-meta/`. Those are the durable knowledge base. Do not ignore them as whole directories.

If no `.gitignore` exists, `bin/setup-vault.sh` writes `templates/vault.gitignore`, which excludes only local UI state, locks, caches, secrets, and large media.

A source checkout used for developing `codex-obsidian` may intentionally ignore runtime vault directories:

```text
/wiki/
/.raw/
/.vault-meta/
```

Remove those rules before turning a source clone into a long-lived personal vault.

Recommended vault exclusions:

```
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/workspace-visual.json
.smart-connections/
.obsidian-git-data
.trash/
.vault-meta/locks/*
.vault-meta/chunks/
.vault-meta/bm25/
.vault-meta/hook.log
.DS_Store
```

`workspace.json` changes constantly as you move panes around. Excluding it keeps the diff clean.

After running `bin/setup-multi-agent.sh`, Codex hooks are configured in `.codex/hooks.json`. The `PostToolUse` hook auto-commits `wiki/`, `.raw/`, and `.vault-meta/` changes when no wiki lock is active.

---

## Obsidian Git Plugin

After installing the plugin (see `plugins.md`):

Settings > Obsidian Git:
- Auto backup interval: **15 minutes**
- Auto backup after file change: on
- Push on backup: on (if you have a remote)
- Commit message: `vault: auto backup {{date}}`

This runs silently in the background. You get a full history of every note without thinking about it.

---

## Remote (Optional)

To back up to GitHub:

```bash
git remote add origin https://github.com/yourname/your-vault
git push -u origin main
```

Keep the repo private if the vault contains personal notes.
