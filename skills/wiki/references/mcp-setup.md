# MCP / Transport Setup

codex-obsidian does not require MCP. The preferred desktop transport is Obsidian CLI; filesystem access is the always-available fallback.

## Recommended: Obsidian CLI

Use this first when Obsidian 1.12+ is installed:

```bash
command -v obsidian-cli && obsidian-cli --version
bash scripts/detect-transport.sh --force
```

Common operations:

```bash
obsidian-cli list /path/to/vault wiki/
obsidian-cli read /path/to/vault wiki/index.md
obsidian-cli write /path/to/vault wiki/new-note.md < content.md
obsidian-cli search /path/to/vault "query term"
```

This path needs no Obsidian plugin, no API key, no TLS bypass, and no MCP server process.

## Fallback: Filesystem

If Obsidian CLI is unavailable, Codex can read and edit markdown files directly through normal filesystem tools. Skills should still acquire `scripts/wiki-lock.sh` locks before writing wiki pages.

## Optional MCP

If your Codex environment is configured with MCP servers, you can connect an Obsidian MCP server such as:

- `mcp-obsidian` with the Obsidian Local REST API plugin.
- `@bitbonsai/mcpvault` for filesystem-backed vault access.

MCP configuration is host-specific, so this project does not hardcode a tool-specific MCP setup command. Prefer the Codex app or CLI configuration flow for your environment, then rerun:

```bash
bash scripts/detect-transport.sh --force
```

## Security Notes

- Avoid exposing Obsidian REST API beyond `127.0.0.1`.
- Avoid global TLS bypasses unless you understand the risk.
- Never store API keys inside wiki pages or committed config.
- Filesystem fallback is often the safest local default.
