# codex-obsidian：详细快速开始

这份文档把首次使用分成两种情况：

- 从零开始创建一个新的 vault；
- 已经有一个 Obsidian vault，只想把 `codex-obsidian` 接进去。

README 只保留最短路径；这里记录完整步骤、mode 选择和常见判断。

---

## 场景一：从零开始创建 vault

这是最简单的路径，也就是把 release 解压后的 `codex-obsidian` 目录作为 Obsidian vault 使用。推荐从 release zip/tarball 开始，而不是直接把开发 clone 当作长期 vault。

### 1. 获取 release 并初始化 Git

```bash
# 下载并解压 release 后进入目录
cd codex-obsidian
git init
```

后续命令都在这个 `codex-obsidian` 目录里执行。

个人 vault 的 Git 历史应该跟踪 `wiki/`、`.raw/` 和 `.vault-meta/`。如果你是用源码 clone 代替 release，先检查根目录 `.gitignore`，不要保留这些整体忽略规则：

```text
/wiki/
/.raw/
/.vault-meta/
```

源码开发仓库忽略这些目录是为了避免提交演示运行态；个人 vault 不应该忽略它们。

### 2. 安装 skills

```bash
bash bin/setup-multi-agent.sh
```

这个脚本会把当前仓库的 `skills/` 链接到：

```text
~/.codex/skills/codex-obsidian
```

它也会写入 Codex 项目 hooks：

```text
.codex/hooks.json
```

这些 hooks 会在新会话开始时读取 `wiki/hot.md`，并在 `save`、`ingest` 等写入结束后自动提交 `wiki/`、`.raw/`、`.vault-meta/` 的变化。Codex 下次进入这个 vault 时可能会要求你信任项目 hooks。

如果当前 Codex 会话没有立刻看到新 skills，开一个新会话最稳。

### 3. 初始化 vault 运行态目录

```bash
bash bin/setup-vault.sh
```

它会创建：

- `.raw/`：原始资料区；
- `wiki/`：Codex 生成和维护的知识库；
- `.vault-meta/`：运行状态、锁、mode、检索缓存；
- `.obsidian/`：Obsidian 配置和 CSS snippet；
- `_templates/`：wiki 页面模板。

脚本是幂等的：已有文件不会被覆盖。

如果当前目录还没有 `.gitignore`，脚本会写入 `templates/vault.gitignore` 的 vault 版本：它不会整体忽略 `wiki/`、`.raw/` 或 `.vault-meta/`，只忽略锁文件、缓存、Obsidian UI 状态、密钥和大媒体文件。

初始化后建议立刻提交一次：

```bash
git add -A
git commit -m "Initial codex-obsidian vault"
```

### 4. 在 Obsidian 中打开 vault

打开 Obsidian：

```text
Manage Vaults -> Open folder as vault -> 选择 codex-obsidian/
```

### 5. 在这个目录启动 Codex

关键点是：Codex 的工作目录也要是这个 vault 目录。

如果使用 Codex CLI：

```bash
cd /path/to/codex-obsidian
codex
```

如果使用 Codex Desktop，在应用里打开 `codex-obsidian` 这个文件夹作为 workspace。

### 6. 执行 `/wiki`

在 Codex 中输入：

```text
/wiki
```

或：

```text
设置这个 wiki
```

`/wiki` 会做语义初始化：确认用途、创建或更新索引页、初始化 `hot.md`，并把后续任务路由给 `wiki-ingest`、`wiki-query`、`wiki-lint` 等 skills。

---

## 场景二：已有一个 Obsidian vault

这种情况下，`codex-obsidian` 仓库只作为工具包；你的实际 vault 在另一个目录。

### 1. 在工具仓库安装 skills

```bash
cd /path/to/codex-obsidian
bash bin/setup-multi-agent.sh /path/to/ExistingVault
```

这一步只需要做一次。传入 vault 路径时，脚本会把 hooks 写到 `/path/to/ExistingVault/.codex/hooks.json`，这样你在已有 vault 里启动 Codex 时也能自动读取 hot cache、自动提交 wiki 运行态变化。

### 2. 对已有 vault 执行 setup

```bash
cd /path/to/codex-obsidian
bash bin/setup-vault.sh /path/to/ExistingVault
```

这个脚本只会补齐缺失的运行态文件，不会覆盖已有同名文件。尽管如此，如果这个 vault 已经有重要内容，建议先做一次 Git commit 或备份。

已有 vault 也应确保 `.gitignore` 没有整体忽略 `wiki/`、`.raw/`、`.vault-meta/`。这些目录是 codex-obsidian 的知识库历史，应该由 Git 跟踪。

### 3. 在已有 vault 目录启动 Codex

```bash
cd /path/to/ExistingVault
codex
```

或在 Codex Desktop 中打开 `/path/to/ExistingVault` 作为 workspace。

然后运行：

```text
/wiki
```

已有笔记不会被自动迁移。你可以把希望作为资料来源的文件放入 `.raw/`，再逐个执行：

```text
ingest .raw/articles/example.md
```

`wiki-ingest` 默认会先给出审阅草稿，等你确认或修正后才写入 wiki。

---

## 怎么描述 Vault 用途？

`/wiki` 可能会问“这个 vault 是做什么的？”。这个答案只用于生成概览、领域页和初始化说明，不会再创建额外的用途目录。

可以直接用一句话描述：

```text
这是一个项目/业务知识库、个人第二大脑，以及 LLM/知识管理相关研究资料库。
```

默认物理布局保持核心目录：`sources/`、`entities/`、`concepts/`、`domains/`、`questions/`、`comparisons/`、`sessions/`、`canvases/`、`meta/`。新页面如何归档由 `wiki-mode` 决定。

---

## 怎么选择 wiki-mode？

`wiki-mode` 描述的是 **新页面怎么归档**，由 `bin/setup-mode.sh` 写入 `.vault-meta/mode.json`。

```bash
bash bin/setup-mode.sh
```

四种模式：

- **Generic**：默认模式，使用 `wiki/sources/`、`wiki/entities/`、`wiki/concepts/`、`wiki/sessions/`；
- **LYT**：MOC + atomic notes；
- **PARA**：Projects / Areas / Resources / Archives；
- **Zettelkasten**：扁平时间戳 ID 原子笔记。

第一次使用建议先保持 **Generic**。等你确定自己真的要按 PARA、LYT 或 Zettelkasten 组织新页面，再切换也不迟。切换只影响之后生成的页面，不会自动迁移旧文件。

---

## 第一次摄取资料

把资料放入 `.raw/` 的合适子目录：

```text
.raw/articles/
.raw/transcripts/
.raw/images/
.raw/data/
```

然后在 Codex 中执行：

```text
ingest .raw/articles/example.md
```

Codex 会先读取完整资料，并给出摘要草稿、关键主张、建议强调点、拟创建/更新页面和不确定点。你确认或修正后，它才会写入 wiki。只有命令中明确包含 `强制跳过交互过程`，才会跳过这一步自主执行。

确认摄取后，Codex 会更新：

- `wiki/sources/`
- `wiki/entities/`
- `wiki/concepts/`
- `wiki/index.md`
- `wiki/log.md`
- `wiki/hot.md`
- `.raw/.manifest.json`

---

## 常见问题

### 为什么推荐 release 而不是 clone？

源码 clone 面向开发 `codex-obsidian` 本身，通常会忽略运行态目录，避免把演示 wiki 提交进工具仓库。个人 vault 面向长期使用，`wiki/`、`.raw/` 和 `.vault-meta/` 应进入 Git；因此更推荐用 release 包创建新目录后重新 `git init`。

### hooks 会自动提交哪些内容？

Codex 的 `PostToolUse` hook 只提交 `wiki/`、`.raw/`、`.vault-meta/` 三类运行态路径，并且会先检查 `wiki-lock.sh` 是否还有活动锁。有锁时跳过，避免提交半写状态。创建 `.vault-meta/auto-commit.disabled` 可以关闭自动提交。

### 为什么运行了 setup 但 `/wiki` 没触发？

当前 Codex 会话可能是在 skills 安装前启动的。新开一个 Codex 会话，或重新打开 workspace。

### `setup-vault.sh` 会覆盖我的已有笔记吗？

不会覆盖已有同名文件。它通过 `write_if_missing` 创建缺失文件；已存在的文件会跳过。

### 还需要选择 A-F 用例模式吗？

不需要。早期 A-F 用例模式只描述用途，但没有和写入路由完整打通。当前版本不再按这些模式创建物理目录；如需改变归档方式，使用 `wiki-mode`。

### 已有 vault 里的旧笔记会自动进入 wiki 吗？

不会。你需要指定哪些内容要作为资料摄取，或者把来源文件放入 `.raw/` 后执行 `ingest`。
