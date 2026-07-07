#!/usr/bin/env bash
# codex-obsidian vault setup script
# Usage: bash bin/setup-vault.sh [optional: /path/to/vault]
#
# The repository does not track a root wiki/. This script creates the runtime
# Obsidian vault structure on demand and keeps existing user content intact.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
VAULT="${1:-$REPO_ROOT}"
OBSIDIAN="$VAULT/.obsidian"
TODAY="$(date +%Y-%m-%d)"
NOW="$(date +%Y-%m-%dT%H:%M:%S%z)"

echo "Setting up codex-obsidian vault at: $VAULT"

mkdir -p "$OBSIDIAN/snippets"
mkdir -p "$VAULT/.raw/articles" "$VAULT/.raw/transcripts" "$VAULT/.raw/images" "$VAULT/.raw/data"
mkdir -p "$VAULT/.vault-meta/locks"
mkdir -p "$VAULT/wiki/sources" "$VAULT/wiki/entities" "$VAULT/wiki/concepts" "$VAULT/wiki/domains"
mkdir -p "$VAULT/wiki/comparisons" "$VAULT/wiki/questions" "$VAULT/wiki/sessions" "$VAULT/wiki/canvases" "$VAULT/wiki/meta"
mkdir -p "$VAULT/_templates"

write_if_missing() {
  local path="$1"
  if [ -e "$path" ]; then
    echo "--  exists: ${path#$VAULT/}"
    return
  fi
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  echo "OK  created: ${path#$VAULT/}"
}

write_if_missing "$OBSIDIAN/graph.json" <<'JSON'
{
  "collapse-filter": false,
  "search": "path:wiki",
  "showTags": false,
  "showAttachments": false,
  "hideUnresolved": true,
  "showOrphans": false,
  "collapse-color-groups": false,
  "colorGroups": [
    { "query": "path:wiki/domains", "color": { "a": 1, "rgb": 5227007 } },
    { "query": "path:wiki/entities", "color": { "a": 1, "rgb": 12945088 } },
    { "query": "path:wiki/concepts", "color": { "a": 1, "rgb": 14474410 } },
    { "query": "path:wiki/sources", "color": { "a": 1, "rgb": 13537656 } },
    { "query": "path:wiki/questions", "color": { "a": 1, "rgb": 6986069 } },
    { "query": "path:wiki/comparisons", "color": { "a": 1, "rgb": 13724009 } },
    { "query": "path:wiki/sessions", "color": { "a": 1, "rgb": 5676246 } },
    { "query": "path:wiki/canvases", "color": { "a": 1, "rgb": 11914920 } },
    { "query": "path:wiki/meta", "color": { "a": 1, "rgb": 10280190 } }
  ],
  "showArrow": true,
  "textFadeMultiplier": -1,
  "nodeSizeMultiplier": 1.6,
  "lineSizeMultiplier": 1.1,
  "centerStrength": 0.5,
  "repelStrength": 30,
  "linkStrength": 1.5,
  "linkDistance": 120,
  "scale": 1.0
}
JSON

write_if_missing "$OBSIDIAN/app.json" <<'JSON'
{
  "userIgnoreFilters": [
    "skills/",
    "scripts/",
    "bin/",
    "tests/",
    "README.md",
    "WIKI.md"
  ]
}
JSON

write_if_missing "$OBSIDIAN/appearance.json" <<'JSON'
{
  "enabledCssSnippets": [
    "vault-colors"
  ]
}
JSON

write_if_missing "$OBSIDIAN/snippets/vault-colors.css" <<'CSS'
/* codex-obsidian: wiki folder color hints */
.nav-folder-title[data-path^="wiki/domains"] { color: #4fc1ff; }
.nav-folder-title[data-path^="wiki/entities"] { color: #c586c0; }
.nav-folder-title[data-path^="wiki/concepts"] { color: #dcdcaa; }
.nav-folder-title[data-path^="wiki/sources"] { color: #ce9178; }
.nav-folder-title[data-path^="wiki/questions"] { color: #6a9955; }
.nav-folder-title[data-path^="wiki/comparisons"] { color: #d16969; }
.nav-folder-title[data-path^="wiki/sessions"] { color: #569cd6; }
.nav-folder-title[data-path^="wiki/canvases"] { color: #b5cea8; }
.nav-folder-title[data-path^="wiki/meta"] { color: #9cdcfe; }

.callout[data-callout="contradiction"] {
  --callout-color: 180, 80, 70;
  --callout-icon: alert-triangle;
}
.callout[data-callout="gap"] {
  --callout-color: 180, 135, 40;
  --callout-icon: search;
}
.callout[data-callout="key-insight"] {
  --callout-color: 70, 130, 90;
  --callout-icon: lightbulb;
}
.callout[data-callout="stale"] {
  --callout-color: 120, 120, 120;
  --callout-icon: clock;
}
CSS

if [ -d "$REPO_ROOT/_templates" ]; then
  rsync -a "$REPO_ROOT/_templates/" "$VAULT/_templates/"
  echo "OK  templates synced: _templates/"
fi

if [ ! -e "$VAULT/.gitignore" ] && [ -f "$REPO_ROOT/templates/vault.gitignore" ]; then
  cp "$REPO_ROOT/templates/vault.gitignore" "$VAULT/.gitignore"
  echo "OK  created: .gitignore"
fi

if [ -f "$VAULT/.gitignore" ] && grep -Eq '^[[:space:]]*/?(wiki|\.raw|\.vault-meta)/[[:space:]]*$' "$VAULT/.gitignore"; then
  echo "WARN .gitignore ignores wiki/, .raw/, or .vault-meta/ as a whole."
  echo "WARN Hook auto-commit will not track ignored runtime vault changes."
  echo "WARN This is expected in a development clone, but not recommended for a personal release vault."
fi

write_if_missing "$VAULT/.raw/.manifest.json" <<JSON
{
  "version": 1,
  "created": "$TODAY",
  "description": "codex-obsidian 摄取清单。由 wiki-ingest 维护，请不要手动编辑。",
  "sources": {},
  "address_map": {}
}
JSON

write_if_missing "$VAULT/.vault-meta/address-counter.txt" <<'TEXT'
1
TEXT

write_if_missing "$VAULT/.vault-meta/legacy-pages.txt" <<TEXT
# codex-obsidian legacy-pages manifest
# rollout: $TODAY
#
# 每行一个 wiki 相对路径。列在这里的旧页面不会被地址校验视为错误。
TEXT

write_if_missing "$VAULT/.vault-meta/tiling-thresholds.json" <<'JSON'
{
  "version": 1,
  "model": "nomic-embed-text",
  "bands": {
    "error": 0.90,
    "review": 0.80
  },
  "calibrated": false,
  "calibration_pairs_labeled": 0,
  "notes": "Conservative seed thresholds, not calibrated against this vault."
}
JSON

write_if_missing "$VAULT/wiki/index.md" <<EOF
---
type: meta
title: "Wiki 索引"
created: $TODAY
updated: $TODAY
status: active
language: zh
---

# Wiki 索引

## 来源

- 暂无。把资料放入 \`.raw/\` 后，让 Codex 执行 \`ingest <文件名>\`。

## 实体

- 暂无。

## 概念

- 暂无。

## 问题

- 暂无。
EOF

write_if_missing "$VAULT/wiki/hot.md" <<EOF
---
type: meta
title: "热缓存"
created: $TODAY
updated: $NOW
status: active
language: zh
---

# 热缓存

## 最近状态

${TODAY}：vault 已初始化，尚未摄取资料。

## 关键事实

- \`.raw/\` 用于保存原始资料。
- \`wiki/\` 用于保存 Codex 生成的知识页面。

## 活跃线程

- 等待第一次资料摄取。
EOF

write_if_missing "$VAULT/wiki/log.md" <<EOF
---
type: meta
title: "操作日志"
created: $TODAY
updated: $TODAY
status: active
language: zh
---

# 操作日志

## [$TODAY] setup | 初始化 codex-obsidian vault

- 创建基础目录、索引、热缓存和模板。
- 下一步：把资料放入 \`.raw/\`，然后执行 \`ingest <文件名>\`。
EOF

write_if_missing "$VAULT/wiki/overview.md" <<EOF
---
type: meta
title: "Wiki 概览"
created: $TODAY
updated: $TODAY
status: seed
language: zh
---

# Wiki 概览

这个 vault 由 codex-obsidian 初始化。随着资料摄取，Codex 会在这里维护整个知识库的高层摘要、核心主题和未解决问题。
EOF

for section in sources entities concepts domains questions comparisons sessions meta; do
  title="$section"
  case "$section" in
    sources) title="来源索引" ;;
    entities) title="实体索引" ;;
    concepts) title="概念索引" ;;
    domains) title="领域索引" ;;
    questions) title="问题索引" ;;
    comparisons) title="对比索引" ;;
    sessions) title="会话索引" ;;
    meta) title="元信息索引" ;;
  esac
  write_if_missing "$VAULT/wiki/$section/_index.md" <<EOF
---
type: meta
title: "$title"
created: $TODAY
updated: $TODAY
status: active
language: zh
---

# $title

- 暂无条目。
EOF
done

write_if_missing "$VAULT/AGENTS.md" <<'EOF'
# Vault Agent Instructions

这是一个由 codex-obsidian 维护的 Obsidian wiki vault。

## 规则

- `.raw/` 是原始资料区，只读。
- `wiki/` 是 Codex 维护的知识库。
- 默认使用简体中文产出 wiki 内容，frontmatter 写 `language: zh`。
- 回答 wiki 相关问题时先读 `wiki/hot.md`，再读 `wiki/index.md`，最后读具体页面。
- 每次摄取、保存或重要查询后更新 `wiki/index.md`、`wiki/log.md` 和 `wiki/hot.md`。
- Obsidian 内部链接使用 `[[页面名]]`。
EOF

echo ""
echo "Setup complete."
echo ""
echo "Next steps:"
echo "  1. Open Obsidian."
echo "  2. Open folder as vault: $VAULT"
echo "  3. In Codex, run /wiki or say: 设置这个 wiki"
echo "  4. Drop source files into .raw/ and run: ingest <filename>"
