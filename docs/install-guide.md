# codex-obsidian：安装指南

**Codex + Obsidian 知识库伴侣**  
当前项目：`codex-obsidian`  
上游来源：[`AgriciDaniel/claude-obsidian`](https://github.com/AgriciDaniel/claude-obsidian)

> 迁移说明：本文从上游安装文档翻译并改写而来，面向当前的 Codex-first、中文-first 项目。上游的 Claude Code plugin 安装方式不再作为主路径；本仓库默认通过本地 skills 链接安装到 Codex。

---

## codex-obsidian 是什么？

`codex-obsidian` 是一组 Codex skills + Obsidian vault 约定，用来构建一个长期演化的本地知识库。你把原始资料放进 `.raw/`，Codex 负责读取、拆解、建页、互链、检索、回答问题，并把重要对话保存回 `wiki/`。

它继承了 Andrej Karpathy 的 LLM Wiki 思路：知识不是停留在一次聊天里，而是沉淀成可继续复用的 wiki。

---

## 前置条件

| 工具 | 获取方式 | 备注 |
|---|---|---|
| **Codex** | 使用本地 Codex 环境 | skills 会链接到 `~/.codex/skills/` |
| **Obsidian** | [obsidian.md](https://obsidian.md) | 免费，可直接打开本仓库或指定 vault 目录 |
| **Git** | 大多数系统已内置 | 用于版本管理和回滚 |
| **Python 3** | 系统或包管理器安装 | 检索、模式路由、lint 等脚本需要 |

可选扩展：

| 扩展 | 用途 |
|---|---|
| `flock` | DragonScale 地址分配和部分缓存锁 |
| `ollama` + `nomic-embed-text` | 语义重复页检查、可选 rerank |

---

## 安装

### 方式 1：用 release 创建新 vault（推荐）

```bash
# 下载并解压 release 后进入目录
cd codex-obsidian
git init
bash bin/setup-multi-agent.sh
bash bin/setup-vault.sh
git add -A
git commit -m "Initial codex-obsidian vault"
```

然后在 Obsidian 中选择：

```text
Manage Vaults -> Open folder as vault -> 选择 codex-obsidian/
```

回到 Codex，在同一目录中输入 `/wiki`，或者直接说“设置这个 wiki”。

不建议直接把源码 clone 当作长期个人 vault，除非你先处理 `.gitignore`。源码仓库为了避免提交演示运行态，可能会忽略 `/wiki/`、`/.raw/`、`/.vault-meta/`；个人 vault 应该跟踪这些目录。

### 方式 2：在另一个目录生成 vault

如果你希望工具仓库和实际 vault 分开：

```bash
cd /Users/charles/Projects/codex-obsidian
bash bin/setup-multi-agent.sh ~/Documents/CodexVault
bash bin/setup-vault.sh ~/Documents/CodexVault
```

然后在 Obsidian 中打开 `~/Documents/CodexVault`。

传入 vault 路径时，`setup-multi-agent.sh` 会在该 vault 下写入 `.codex/hooks.json`，用于读取 hot cache 和自动提交 wiki 运行态变化。

### 方式 3：手工安装 skills

`setup-multi-agent.sh` 的核心动作是把本仓库的 `skills/` 链接到 Codex skills 目录。等价手工命令：

```bash
ln -s "$(pwd)/skills" ~/.codex/skills/codex-obsidian
```

如果链接已存在，先确认它指向当前仓库，再决定是否替换。

脚本还会安装 Codex hooks。手工安装时，需要把本仓库的 `.codex/hooks.json` 复制到实际 vault 的 `.codex/hooks.json`，或按该文件内容把命令路径改成当前工具仓库的绝对路径。

---

## 第一次使用

### 1. 初始化 vault

在 Codex 中触发 `/wiki`。Codex 会：

- 检查 vault 是否已经初始化；
- 创建核心目录和页面；
- 生成 `wiki/index.md`、`wiki/hot.md`、`wiki/log.md`、`wiki/overview.md`；
- 保持新建 wiki 内容默认为简体中文。

根目录的 `wiki/`、`.raw/`、`.obsidian/`、`.vault-meta/` 都是运行态内容，由 `bin/setup-vault.sh` 创建。本仓库不把这些目录当源码维护。

作为个人 vault 使用时，`wiki/`、`.raw/`、`.vault-meta/` 是知识库历史，不应被整体忽略。`setup-vault.sh` 会在没有 `.gitignore` 时写入 vault 版本模板，只忽略锁、缓存、Obsidian UI 状态、密钥和大文件。

### 2. 放入第一份资料

把任意资料放入 `.raw/`：

- PDF
- Markdown
- 访谈或会议记录
- 网页正文
- URL 列表
- 图片或截图说明

然后告诉 Codex：

```text
ingest <文件名>
```

Codex 会先读取资料并给出审阅草稿，包括摘要、关键主张、建议强调点和拟创建/更新页面。你确认或修正后，它才会生成 source/entity/concept 等 wiki 页面，并更新索引和日志。只有命令中明确包含 `强制跳过交互过程`，才会跳过审阅自主执行。

### 3. 提问

```text
what do you know about <主题>?
```

或中文：

```text
你知道哪些关于 <主题> 的内容？
```

Codex 会优先读取 `wiki/hot.md`，再查 `wiki/index.md` 和相关页面，最后给出基于本地 wiki 的综合回答。

---

## 常用命令

| 命令 | Codex 做什么 |
|---|---|
| `/wiki` | 检查、初始化或继续维护 wiki |
| `ingest [file]` | 读取资料，先给出审阅草稿；确认后生成 wiki 页面，更新索引和日志 |
| `ingest all of these` | 批量处理多份资料；默认逐份审阅，确认后写入，再做互链 |
| `what do you know about X?` | 从 wiki 中检索并综合回答 |
| `/save` | 把当前对话保存成 wiki 笔记 |
| `/save [name]` | 用指定标题保存当前对话 |
| `/autoresearch [topic]` | 多轮搜索、读取、综合并归档 |
| `/canvas` | 打开或创建 Obsidian Canvas |
| `/canvas add image [path]` | 往 Canvas 加入图片 |
| `/canvas add text [content]` | 往 Canvas 加入 Markdown 文本卡 |
| `/canvas add pdf [path]` | 往 Canvas 加入 PDF |
| `/canvas add note [page]` | 把 wiki 页面固定为链接卡片 |
| `lint the wiki` | 检查孤儿页、死链、缺口、地址和语义重叠 |
| `update hot cache` | 刷新 `wiki/hot.md` 的近期上下文摘要 |

---

## Obsidian 插件建议

`setup-vault.sh` 会生成 Obsidian 配置和 CSS 片段，但部分社区插件仍需你在 Obsidian 中启用或安装。

建议启用：

| 插件 | 用途 |
|---|---|
| Calendar | 右侧日历、字数和任务点 |
| Thino | 快速 memo 捕获 |
| Excalidraw | 手绘、图像标注 |
| Banners | 通过 `banner:` frontmatter 显示头图 |

建议从 Community Plugins 安装：

| 插件 | 用途 |
|---|---|
| Dataview | 驱动 dashboard 查询 |
| Templater | 根据模板自动补齐 frontmatter |
| Obsidian Git | 定时提交 vault 变更 |

---

## CSS 片段

`setup-vault.sh` 会启用三个 CSS snippets：

| Snippet | 效果 |
|---|---|
| `vault-colors` | 在文件树中按 wiki 文件夹着色 |
| `ITS-Dataview-Cards` | 把 Dataview 查询渲染成卡片网格 |
| `ITS-Image-Adjustments` | 控制图片尺寸；可在 embed 后追加 `\|100` |

---

## 四种组织模式

当前项目支持 `wiki-mode` 路由，新页面可按不同方法论归档：

| 模式 | 适用场景 |
|---|---|
| **Generic** | 不使用特定方法论，沿用默认 `sources/entities/concepts/sessions` 结构 |
| **LYT** | 用 MOC（Map of Content）组织主题簇和链接导航 |
| **PARA** | 按 Projects / Areas / Resources / Archives 组织行动和资料 |
| **Zettelkasten** | 原子笔记、唯一 ID、高密度双向链接 |

交互式设置：

```bash
bash bin/setup-mode.sh
```

非交互式设置：

```bash
bash bin/setup-mode.sh --mode lyt
```

详见 [methodology-modes-guide.md](methodology-modes-guide.md)。

---

## MCP 设置（可选）

基础用法不需要 MCP。Codex 可以直接通过文件系统读写 vault。只有当你想让 agent 通过 Obsidian Local REST API 或独立 MCP server 操作 vault 时，才需要 MCP。

### 方案 A：Local REST API

1. 在 Obsidian 中安装 **Local REST API** 插件；
2. 复制 API key；
3. 按你当前 Codex/MCP 环境添加对应 server 配置。

上游 Claude Code 文档使用的是 `claude mcp add-json`。本项目不把它作为默认安装路径。

### 方案 B：文件系统 MCP

如果你已经在使用文件系统类 MCP server，可以把 vault 路径指向当前目录或实际 vault 目录。否则直接使用 Codex 的本地文件工具即可。

---

## DragonScale Memory（可选）

DragonScale 是可选记忆层扩展，提供：

- log 折叠；
- 稳定页面地址；
- 语义重复页 lint；
- `/autoresearch` 的边界优先主题建议。

启用：

```bash
bash bin/setup-dragonscale.sh
```

详见 [dragonscale-guide.md](dragonscale-guide.md)。

---

## 故障排查

| 问题 | 处理 |
|---|---|
| `/wiki` 没触发 | 确认 `bash bin/setup-multi-agent.sh` 已运行，并检查 `~/.codex/skills/codex-obsidian` |
| Obsidian 打开后没有结构 | 运行 `bash bin/setup-vault.sh`，再重新打开 vault |
| Dashboard 没结果 | 安装并启用 Dataview |
| Excalidraw 无法加载 | 重新运行 `bash bin/setup-vault.sh`，确认插件文件已下载 |
| hot cache 没被读取 | 确认 `wiki/hot.md` 存在；让 Codex 先运行 `/wiki` |
| 语义 lint 被跳过 | 检查 `python3`、`ollama` 和 `nomic-embed-text` 是否可用 |

---

## 跨项目使用

你可以让其他 Codex 项目引用这个 vault。把下面内容加入其他项目的 `AGENTS.md`：

```markdown
## Wiki Knowledge Base
Path: ~/path/to/codex-obsidian

When you need context not in this project:
1. Read wiki/hot.md first.
2. If not enough, read wiki/index.md.
3. If domain detail is needed, read the relevant wiki page.

Do not read the wiki for general coding questions.
```

这样，写代码、内容工作流、研究任务都可以复用同一个长期知识库。

---

## 来源和许可

- 上游项目：[`AgriciDaniel/claude-obsidian`](https://github.com/AgriciDaniel/claude-obsidian)
- 当前项目：`codex-obsidian`
- 许可和第三方 attribution：见仓库根目录 [ATTRIBUTION.md](../ATTRIBUTION.md)

*基于 Andrej Karpathy 的 LLM Wiki pattern。*
