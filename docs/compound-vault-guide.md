# Compound Vault — v1.7 指南

**状态：** 上游 v1.7.0（代号 “Compound Vault refoundation”），发布于 2026-05-17  
**当前迁移：** 本文翻译并改写为 `codex-obsidian` 语境  
**读者：** 从早期版本升级的用户、新采用者、以及要集成这些 primitives 的 skill 作者  
**相关文档：** [dragonscale-guide.md](dragonscale-guide.md)、[install-guide.md](install-guide.md)、[CHANGELOG.md](../CHANGELOG.md)

> 迁移说明：上游文档中的 `claude-obsidian` 是原项目名。当前项目保留架构名 Compound Vault，但运行身份改为 Codex，默认知识库产出语言为简体中文。

---

## 为什么叫 Compound Vault

v1.7 引入了一个系统名：**Compound Vault**。它描述的是整体架构，而不是插件名。上游插件名 `claude-obsidian` 主要承担 SEO 和历史连续性；系统名则覆盖 13 个共同运作的 skills。

三段式定位：

> “复利式 vault，而不是聊天记录。CLI-native，而不是聊天窗口。理解方法论，而不是通用文件夹。”

- **复利式 vault**：继承 Karpathy 的 LLM Wiki 模式。知识跨会话累积，每次 ingest 都让 wiki 更丰富。
- **CLI-native**：Obsidian 1.12 把 `obsidian` 二进制提升为一等接口。上游 v1.7 把它作为优先 transport，MCP 降级为 fallback。
- **理解方法论**：v1.7 先打基础，v1.8 引入 LYT / PARA / Zettelkasten / Generic 的模式路由。

一句话版本：

> **“Karpathy 的 wiki，落在你的 Obsidian 里。”**

---

## 相比 v1.6 改了什么

v1.7 分成四条工作线：substrate、transport、retrieval、concurrency。每条都足够独立，出问题时可以单独回滚。它们不是破坏性升级；旧 vault 不主动启用新功能也能继续工作。

| 工作线 | 内容 | 原因 | 用户动作 |
|---|---|---|---|
| §3.1 Substrate | 三个技能改为强优先 `kepano/obsidian-skills` | 避免和平台拥有者重复实现基础能力 | 上游建议安装 `kepano/obsidian-skills` |
| §3.2 Transport | 新增 `wiki-cli`、`detect-transport.sh` 和决策树 | Obsidian CLI 是最快、最安全的写入路径 | 自动检测 |
| §3.3 Retrieval | 新增 `wiki-retrieve`：contextual prefix + BM25 + cosine rerank | 降低 retrieval failure | 可选运行 `bash bin/setup-retrieve.sh` |
| §3.4 Concurrency | 新增 `wiki-lock.sh`、技能守卫和 hook debounce | 修复多写者潜在损坏问题 | 无需额外设置 |

在 `codex-obsidian` 中，这些机制仍然存在，但面向 Codex 的安装和调用方式已调整。

---

## §3.1 基础层：与 kepano/obsidian-skills 的关系

上游三个 skills 与 `kepano/obsidian-skills` 有重叠：

- `obsidian-markdown`
- `obsidian-bases`
- `canvas`

v1.6 的态度是“如果安装了 kepano，优先使用它”。v1.7 改成“kepano 是 canonical；本仓库副本是 fallback”。

原因很直接：Obsidian CEO Steph Ango 维护的技能集合代表平台方语义。继续并行实现平台基础能力不是好投入。Compound Vault 应该把精力放在 workflow 层：

- ingest
- query
- lint
- autoresearch
- save
- retrieve

当前仓库保留这些技能，作为 Codex 可直接使用的本地版本。

---

## §3.2 默认 Transport：Obsidian CLI 与 fallback 链

上游 v1.7 定义四层 transport：

1. **cli**：`obsidian-cli` 或 Obsidian 1.12+ 二进制。无 MCP server、无 TLS、无插件依赖。
2. **mcp-obsidian**：基于 Local REST API 的 MCP server。
3. **mcpvault**：文件系统 MCP server，支持 BM25 搜索。
4. **filesystem**：直接读写文件。永远可用，是最低 fallback。

检测脚本：

```text
scripts/detect-transport.sh
    |
    +-- 写入 .vault-meta/transport.json
```

生成的结构大致为：

```json
{
  "preferred": "cli|filesystem",
  "fallback_chain": ["cli", "filesystem"],
  "available": {
    "cli": {},
    "filesystem": {}
  }
}
```

skills 在运行时读取 `.vault-meta/transport.json`，然后选择最合适的写入路径。

强制刷新：

```bash
bash scripts/detect-transport.sh --force
```

手工固定某个 transport 时，可以编辑 `.vault-meta/transport.json` 并设置：

```json
{
  "manual_override": true
}
```

这样检测脚本就不会覆盖你的选择。

---

## §3.3 混合检索：wiki-retrieve（可选）

`wiki-retrieve` 用 chunk-level 检索替代简单的页面级读取。它实现了 Anthropic 2024 年 9 月 Contextual Retrieval 思路中的实用子集：

- 按段落边界切 chunk；
- 给每个 chunk 加 1-2 句上下文前缀；
- 用 BM25 做稀疏检索；
- 可选用本地 embedding 做 cosine rerank；
- 去重后返回最相关页面。

### ingest 路径

```text
wiki/<page>.md
  |
  v
scripts/contextual-prefix.py
  |
  +-- .vault-meta/chunks/<address>/chunk-NNN.json
  |
  v
scripts/bm25-index.py build
  |
  +-- .vault-meta/bm25/index.json
```

前缀生成三层 fallback：

| 层级 | 条件 | 行为 |
|---|---|---|
| tier 1 | 有 API key 且允许外发 | 调用 Anthropic API |
| tier 2 | `claude` 在 PATH 且允许外发 | 调用 CLI 子进程 |
| tier 3 | 无外部 LLM | 用 frontmatter 标题和首段生成 synthetic prefix |

在 `codex-obsidian` 中，默认应优先使用本地 synthetic fallback；任何可能外发资料正文的路径都应该显式征得用户同意。

### query 路径

```text
query
  |
  v
scripts/retrieve.py "<query>" --top 5
  |
  +-- scripts/bm25-index.py query
  +-- scripts/rerank.py
  +-- page-address dedupe
  |
  v
caller 读取引用页面并综合回答
```

启用：

```bash
bash bin/setup-retrieve.sh
```

强制无 LLM：

```bash
bash bin/setup-retrieve.sh --no-llm
```

只做诊断：

```bash
bash bin/setup-retrieve.sh --check
```

检测条件：

```bash
[ -x scripts/retrieve.py ] && [ -d .vault-meta/chunks ] && [ -f .vault-meta/bm25/index.json ]
```

条件不满足时，`wiki-query` 回退到 legacy 路径：先读 `hot.md`，再读 `index.md` 和相关页面。

---

## §3.4 多写者安全：wiki-lock

上游 v1.6 只有“单写者”约定，没有强制机制。多个 agent 同时写同一页面时，可能互相覆盖。v1.7 新增 `scripts/wiki-lock.sh`，要求每次 wiki 页面写入前先 acquire，写完后 release。

典型模式：

```bash
if bash scripts/wiki-lock.sh acquire wiki/concepts/Foo.md; then
  # 执行写入
  bash scripts/wiki-lock.sh release wiki/concepts/Foo.md
else
  sleep 2
  bash scripts/wiki-lock.sh acquire wiki/concepts/Foo.md && {
    # 执行写入
    bash scripts/wiki-lock.sh release wiki/concepts/Foo.md
  } || echo "skipped wiki/concepts/Foo.md (locked)"
fi
```

锁实现不是传统长进程 `flock`。因为 agent 的 Bash 调用通常是短进程，`acquire` 和 `release` 不在同一个 PID 中。`wiki-lock.sh` 使用：

- 原子 `noclobber` 写 lockfile；
- 基于 epoch 的 stale age 回收，默认 60 秒；
- release 时直接 `rm -f`；
- PID 只做调试信息，不做身份校验。

PostToolUse hook 会在有锁时推迟 `git add`，避免把半写状态提交进历史。

---

## v1.7 Skill 清单

| Skill | 状态 | 角色 |
|---|---|---|
| `wiki` | core | 初始化、脚手架、子 skill 路由 |
| `wiki-ingest` | core | 原始资料 -> wiki 页面和互链 |
| `wiki-query` | core | 问答；可使用 `wiki-retrieve` |
| `wiki-lint` | core | 健康检查：孤儿页、死链、地址、语义重叠 |
| `wiki-fold` | DragonScale 机制 1 | log 折叠 |
| `wiki-cli` | v1.7 新增 | Obsidian CLI transport wrapper |
| `wiki-retrieve` | v1.7 新增，可选 | contextual + BM25 + rerank |
| `save` | core | 把对话保存为 wiki 笔记 |
| `autoresearch` | core | 迭代式 web research -> wiki |
| `canvas` | core | 可视化 wiki 层 |
| `defuddle` | core | 网页正文清理 |
| `obsidian-markdown` | fallback | Obsidian Flavored Markdown 参考 |
| `obsidian-bases` | fallback | Bases YAML 参考 |

当前 `codex-obsidian` 还保留了 `think` skill，用于 Codex 场景下的结构化思考。

---

## v1.7 脚本清单

| 脚本 | 状态 | 角色 |
|---|---|---|
| `allocate-address.sh` | DragonScale 机制 2 | 原子分配 `c-NNNNNN` 地址 |
| `tiling-check.py` | DragonScale 机制 3 | embedding 重复页 lint |
| `boundary-score.py` | DragonScale 机制 4 | `/autoresearch` frontier scoring |
| `detect-transport.sh` | v1.7 新增 | transport 检测 |
| `contextual-prefix.py` | v1.7 新增 | chunk + 三层 prefix 生成 |
| `bm25-index.py` | v1.7 新增 | 稀疏倒排索引 |
| `rerank.py` | v1.7 新增 | 通过 ollama 做 cosine rerank |
| `retrieve.py` | v1.7 新增 | 混合检索编排器 |
| `wiki-lock.sh` | v1.7 新增 | 单文件 advisory lock |

---

## 测试

`make test` 运行本地 hermetic 测试。它不需要网络、ollama 或任何 API key。

| Target | 文件 | 覆盖 |
|---|---|---|
| `make test-address` | `tests/test_allocate_address.sh` | 地址分配 |
| `make test-tiling` | `tests/test_tiling_check.py` | 语义重复检查 |
| `make test-boundary` | `tests/test_boundary_score.py` | frontier scoring |
| `make test-bm25` | `tests/test_bm25_index.py` | tokenizer、BM25、IDF |
| `make test-retrieve` | `tests/test_retrieve.py` | cosine、rerank、端到端子进程 |
| `make test-lock` | `tests/test_wiki_lock.sh` | acquire、release、stale reap |
| `make test-concurrent` | `tests/test_concurrent_write.sh` | 多写者正确性 |

---

## v1.7 不是什么

- 不是重写。DragonScale 机制 1-4 保留。
- 不是破坏性升级。旧 vault 不启用可选检索时仍按旧行为运行。
- 不是付费插件。许可证仍为 MIT。
- 不是完整 Obsidian GUI 插件外壳。GUI onramp 被推迟到更大版本。
- 不是多 vault federation。该能力留给后续大版本。

---

## 路线图指针

上游 2026 年 5 月 gap analysis 给出了后续方向：

- **v1.8**：方法论模式（LYT / PARA / Zettelkasten / Generic）和周期 review。
- **v1.9**：多模态 ingest adapters（YouTube、PDF、EPUB、图片 OCR）。
- **v2.0**：NotebookLM 类派生输出（音频、测验、闪卡、学习指南）。
- **v2.5+**：Community Plugin GUI 外壳。

在当前 `codex-obsidian` 中，v1.8 的模式路由已经随迁移保留。

---

## 参见

- [docs/dragonscale-guide.md](dragonscale-guide.md)
- [docs/install-guide.md](install-guide.md)
- [wiki/references/transport-fallback.md](../wiki/references/transport-fallback.md)
- [wiki/concepts/DragonScale Memory.md](../wiki/concepts/DragonScale%20Memory.md)
- [Anthropic Contextual Retrieval](https://www.anthropic.com/news/contextual-retrieval)
- [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)
- [Karpathy LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
