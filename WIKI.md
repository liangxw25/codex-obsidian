# LLM Wiki Schema

这是 `codex-obsidian` 生成 vault 时使用的简明 schema。完整工作流由 `skills/` 中的 Agent Skills 执行。

## 结构

```text
vault/
├── .raw/          # 原始资料，保持不可变
├── wiki/          # Codex 生成和维护的知识库
├── _templates/    # Obsidian 模板
├── .vault-meta/   # 检索、锁、地址等运行态元数据
└── AGENTS.md      # vault 级 Codex 说明
```

`wiki/` 的默认结构：

```text
wiki/
├── index.md
├── hot.md
├── log.md
├── overview.md
├── sources/
├── entities/
├── concepts/
├── domains/
├── comparisons/
├── questions/
├── sessions/
├── canvases/
└── meta/
```

## 写作规则

- 默认使用简体中文。
- 每个页面必须有 YAML frontmatter。
- frontmatter 至少包含 `type`、`title`、`created`、`updated`、`status`、`language`。
- 内部引用使用 Obsidian wikilink：`[[页面名]]`。
- `.raw/` 只读；如果要保存 URL 或图片说明，创建新的原始资料副本，不改原文件。
- `wiki/log.md` 只追加新条目，新条目放顶部。
- `wiki/hot.md` 是缓存，不是日记；每次重写成最新约 500 字摘要。

## 查询顺序

Codex 回答 wiki 相关问题时按顺序读取：

1. `wiki/hot.md`
2. `wiki/index.md`
3. 相关子索引，例如 `wiki/concepts/_index.md`
4. 具体页面

不要为了普通编程问题读取 wiki。只在任务需要项目知识、资料综合或用户明确要求基于 wiki 回答时使用。
