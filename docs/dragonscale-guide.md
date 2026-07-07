# DragonScale Memory 指南

DragonScale Memory 是 `codex-obsidian` 的可选扩展。它添加四类保守能力：log 折叠、稳定页面地址、重复页面 lint、以及 `/autoresearch` 的 frontier 主题建议。

先完成基础安装：[docs/install-guide.md](./install-guide.md)。设计背景见运行态 wiki 中的 `wiki/concepts/DragonScale Memory.md`（如果你的 vault 已生成）。

> 迁移说明：本文从上游 `claude-obsidian` v1.6.0 DragonScale 文档翻译并改写而来。当前项目仍保留对应脚本和 skill，但默认运行身份是 Codex。

---

## DragonScale 是什么

### 范围和 opt-in 状态

DragonScale 是 wiki 的记忆层扩展，不是基础 vault 的必需组件。它覆盖：

- rollup；
- deterministic page ID；
- duplicate detection；
- `/autoresearch` 的一个可选 topic-selection 路径。

如果你从不运行：

```bash
bash bin/setup-dragonscale.sh
```

基础安装和默认 skill 行为保持不变。仓库通过 feature detection 判断 DragonScale 是否可用，所以它不会成为硬依赖。

### v1.6.0 提供了什么

上游 v1.6.0 交付四个机制：

| 机制 | 名称 | 文件 |
|---|---|---|
| 机制 1 | Fold Operator | `skills/wiki-fold/` |
| 机制 2 | Deterministic Page Addresses | `scripts/allocate-address.sh` |
| 机制 3 | Semantic Tiling Lint | `scripts/tiling-check.py` |
| 机制 4 | Boundary-First Autoresearch | `scripts/boundary-score.py` |

当前仓库保留这些机制，并由 `wiki-ingest`、`wiki-lint`、`autoresearch` 等 skill 按可用性使用。

---

## 启用前准备

### 基础安装

DragonScale 是 add-on，不替代基础安装。至少先完成：

```bash
bash bin/setup-multi-agent.sh
bash bin/setup-vault.sh
```

然后在 Obsidian 打开 vault，并用 `/wiki` 初始化或继续维护。

启用 DragonScale：

```bash
bash bin/setup-dragonscale.sh
```

也可以指定 vault 路径：

```bash
bash bin/setup-dragonscale.sh /path/to/vault
```

不指定路径时，脚本会从 `bin/` 推断仓库根目录。

### 通用前置条件：flock

`flock` 是通用前置条件。机制 2 用它保护 `.vault-meta/.address.lock`；机制 3 从 Python 中使用它保护 `.vault-meta/.tiling.lock` 的缓存 I/O。

检查：

```bash
command -v flock
```

Linux 通常自带。macOS 可通过 `util-linux` 安装。如果没有 `flock`，setup 也许能创建文件，但地址分配和 tiling cache 不可靠，应视为 blocker。

### 机制 3 的额外条件：python3、ollama、nomic-embed-text

语义重复页检查需要本地 embedding stack：

```bash
command -v python3
curl -sS http://127.0.0.1:11434/api/version
ollama pull nomic-embed-text
```

setup 脚本不会替你安装这些依赖，只会检查并报告状态。机制 4 只需要 `python3`，不需要 ollama。机制 1 和 2 不需要 Python 或 ollama。

### 可选依赖缺失时会怎样

DragonScale 设计为 fail closed 或 clean no-op。

如果缺少 `python3`：

- 机制 3 不运行；
- 机制 4 不运行；
- 机制 1 和 2 仍可工作。

如果 ollama 不可达，`scripts/tiling-check.py` 返回 `10`。如果模型缺失，返回 `11`。`wiki-lint` 应把这些视为“跳过 semantic tiling”，而不是整个 lint 失败。

如果 boundary helper 失败，`/autoresearch` 回退到普通的“询问用户主题”流程。

---

## Setup

运行：

```bash
bash bin/setup-dragonscale.sh
```

脚本是幂等的，重复运行安全，不会覆盖已经创建的运行态文件。

它会先检查：

- `scripts/allocate-address.sh`
- `scripts/tiling-check.py`
- `skills/wiki-fold/SKILL.md`

缺失任何一个都会停止，并提示重新安装。

setup 会做：

- 让 `scripts/allocate-address.sh` 可执行；
- 让 `scripts/tiling-check.py` 可执行；
- 创建 `.vault-meta/`；
- 创建 address、tiling、legacy-baseline 状态文件；
- 创建 `.raw/.manifest.json`；
- 运行最终 sanity checks。

setup 不会做：

- 安装 ollama；
- pull `nomic-embed-text`；
- 给旧页面回填 address；
- 执行 fold；
- 执行 semantic tiling；
- 重写已有 wiki 页面。

### 创建的状态文件

`.vault-meta/` 中：

- `address-counter.txt`
- `tiling-thresholds.json`
- `legacy-pages.txt`

`.raw/` 中：

- `.manifest.json`

`address-counter.txt` 初始为 `1`，所以新 vault 的第一个地址是 `c-000001`。

`tiling-thresholds.json` 初始阈值：

```json
{
  "error": 0.90,
  "review": 0.80,
  "calibrated": false
}
```

这些是保守种子，不是针对你 vault 校准后的真值。

`legacy-pages.txt` 会带一个 rollout 标记：

```text
# rollout: YYYY-MM-DD
```

`wiki-lint` 用它区分 legacy 页面和 DragonScale 启用后新建的页面。

### 验证 setup

查看下一个地址但不占用：

```bash
./scripts/allocate-address.sh --peek
```

查看运行态状态：

```bash
ls -1 .vault-meta
```

检查 tiling readiness：

```bash
python3 ./scripts/tiling-check.py --peek
```

检查 boundary helper：

```bash
python3 ./scripts/boundary-score.py --top 5
```

如果 vault 很小或内部连接很紧密，boundary helper 可能没有正分 frontier 页面。这仍然是有效运行结果。

---

## 机制 1：Fold Operator

Fold operator 是 log rollup。它读取 `wiki/log.md` 中最近的 `2^k` 条 entry，在 `wiki/folds/` 下生成一个 extractive fold 页面。

fold 是 additive 的：不删除、不移动、不重写子 entry。fold 也是 extractive 的：输出里的结论和主题必须能追溯到 child log entry。

当前实现刻意保持窄范围：对原始 log entry 做 flat fold。概念规格中提到的 fold-of-folds 还不属于当前 skill 范围。

fold ID 对同一个范围是确定性的：

```text
fold-k{K}-from-{EARLIEST-DATE}-to-{LATEST-DATE}-n{COUNT}
```

如果完全相同的 fold 已存在，skill 应该停止，避免写重复页面。

适用场景：

- 同一主题完成多次 ingest 后；
- 一段密集 research session 后；
- `wiki/log.md` 变长、难以扫描前。

不要把 fold 当垃圾回收。它总结，但不靠删除来压缩。

dry-run 示例：

```text
fold the log, dry-run k=3
```

这表示预览最近 `2^3 = 8` 条 entry 的 fold。

commit 示例：

```text
fold the log, commit k=3
```

建议先 dry-run，确认内容正确后再 commit。

关闭机制 1：停止调用 `wiki-fold`。已有 fold 页面可以保留，也可以手工删除。

---

## 机制 2：稳定页面地址

地址 frontmatter：

```yaml
address: c-000042
```

`c-` 表示 creation-order counter；数字补齐到六位。这不是内容哈希。它的目标是稳定、可预测、可引用。

helper 模式：

```bash
./scripts/allocate-address.sh
./scripts/allocate-address.sh --peek
./scripts/allocate-address.sh --rebuild
```

- 默认模式：占用并打印下一个地址；
- `--peek`：只读；
- `--rebuild`：根据已有最高 `c-NNNNNN` 重算 counter。

`wiki-ingest` 仅在以下条件满足时自动加地址：

```bash
[ -x ./scripts/allocate-address.sh ] && [ -d ./.vault-meta ]
```

`wiki-lint` 仅在以下条件满足时验证地址：

```bash
[ -x ./scripts/allocate-address.sh ] && [ -f ./.vault-meta/address-counter.txt ]
```

lint 检查：

- 地址格式；
- 地址唯一性；
- counter 与 `--peek` 一致性；
- rollout 后页面是否缺地址；
- `.raw/.manifest.json` 中 `address_map` 是否一致。

硬规则：不要直接编辑 `.vault-meta/address-counter.txt`。只能通过 `scripts/allocate-address.sh` 修改。

关闭机制 2：

1. 停止依赖地址分配的 ingest；
2. 如果要让 feature detection 关闭，可移除 `.vault-meta/`；
3. 停止调用 `./scripts/allocate-address.sh`。

已有 `address:` 字段可以保留，它们会变成普通元数据。

---

## 机制 3：Semantic Tiling Lint

机制 3 用 embedding 查找潜在重复页面。它扫描 `wiki/` 下的 Markdown，排除：

- `wiki/folds/`
- `wiki/meta/`
- `index.md`、`log.md`、`hot.md`、`overview.md`、`dashboard.md`、`Wiki Map.md`、`getting-started.md`
- frontmatter 中 `type: meta`
- frontmatter 中 `type: fold`
- symlink 或逃出 vault root 的路径

它为每个页面计算一个 embedding，再按 cosine similarity 比较候选重叠。

默认分档：

- `>= 0.90`：error；
- `0.80 - 0.90`：review；
- `< 0.80`：pass。

helper 不会自动合并页面，只报告候选项。

检查 readiness：

```bash
python3 ./scripts/tiling-check.py --peek
```

默认只信任本地 ollama：

```text
http://127.0.0.1:11434
```

如果确实要使用远程 ollama，必须显式允许，因为页面正文会作为 embedding 输入发送出去：

```bash
python3 ./scripts/tiling-check.py --allow-remote-ollama --peek
```

常用命令：

```bash
python3 ./scripts/tiling-check.py --peek
python3 ./scripts/tiling-check.py --rebuild-cache
python3 ./scripts/tiling-check.py --report wiki/meta/tiling-report-YYYY-MM-DD.md
```

关闭机制 3：停止调用 `tiling-check.py`，并避免在 `wiki-lint` 中使用 semantic-tiling 路径。不要为了只关闭机制 3 而删除 `.vault-meta/`，因为它也是机制 2 和 4 的 gate。

---

## 机制 4：Boundary-First Autoresearch

机制 4 给 wiki 图中的 frontier 页面打分。公式：

```text
boundary_score(p) = (out_degree(p) - in_degree(p)) * recency_weight(p)
```

高分页面通常：

- 指向许多可继续研究的页面；
- 收到的入链相对少；
- 最近更新过，仍像 frontier。

命令示例：

```bash
python3 ./scripts/boundary-score.py --json --top 5
```

这是 `autoresearch` 生成候选 topic 时使用的形态。

### agenda-control 注意事项

这个机制不仅描述 vault，也会影响 agent 接下来建议研究什么。因此它跨过了“记忆”和“计划”的边界。

项目把它设计成 opt-in，并要求明确标注。如果你只想要严格意义上的 memory layer，就不要使用无 topic 的 `/autoresearch` 路径，或不要启用 boundary scorer。

### `/autoresearch` 的行为

当机制 4 可用，并且用户只输入 `/autoresearch` 而没有给 topic 时，skill 会：

1. 检查 `scripts/boundary-score.py`；
2. 检查 `./.vault-meta`；
3. 检查 `python3`；
4. 运行 `./scripts/boundary-score.py --json --top 5`；
5. 展示 top frontier 页面作为候选主题；
6. 允许用户选择、输入自定义主题或拒绝。

如果 helper 非零退出、返回非法 JSON 或空结果，skill 回退到：

```text
What topic should I research?
```

helper 只建议，最终由用户决定。

关闭机制 4：

- 停止运行 `python3 ./scripts/boundary-score.py`；
- 使用 `/autoresearch [topic]` 明确给出主题；
- 避免无 topic 的 `/autoresearch`。

---

## 操作策略

### 单写者规则

DragonScale 的地址分配路径假设单写者。allocator 用 `flock` 保护 counter，但这不等于整个 wiki 都是多写者安全系统。

安全策略：

- 同一时间只有一个 ingest writer；
- 同一时间只有一个地址分配路径；
- 不直接手工编辑 counter 状态。

机制 1 通常由人触发，容易串行化。机制 3 对缓存 I/O 有锁。机制 4 是只读。

### Feature detection 和 graceful fallback

DragonScale 不应被假设存在，而应被检测：

- `wiki-ingest` 只在 allocator 可执行且 `.vault-meta/` 存在时分配地址；
- `wiki-lint` 只在 allocator 和 `address-counter.txt` 存在时验证地址；
- `wiki-lint` 只在 helper 和 `python3` 可用时尝试 semantic tiling；
- `autoresearch` 只在 helper、`.vault-meta/` 和 `python3` 可用时启用 boundary-first selection。

不满足条件时，回退到基础行为。这是预期姿态。

---

## 故障排查

### 缺少 flock

检查：

```bash
command -v flock
```

缺失时，安装系统对应包，然后重新运行：

```bash
bash bin/setup-dragonscale.sh
```

不要通过直接编辑 `.vault-meta/address-counter.txt` 绕过。

### 缺少 ollama 或模型

这只影响机制 3。

检查 ollama：

```bash
curl -sS http://127.0.0.1:11434/api/version
```

检查 tiling：

```bash
python3 ./scripts/tiling-check.py --peek
```

如果退出码是 `10`，ollama 不可达。如果是 `11`，拉取模型：

```bash
ollama pull nomic-embed-text
```

机制 4 不需要 ollama；只想用 boundary-first autoresearch 时，`python3` 足够。

### 安全回滚

无需卸载整个仓库：

- 机制 1：停止调用 `wiki-fold`；
- 机制 2：停止使用 `allocate-address.sh`，已有 `address:` 留作普通元数据；
- 机制 3：停止运行 `tiling-check.py`，不走 semantic-tiling lint；
- 机制 4：停止运行 `boundary-score.py`，避免无 topic `/autoresearch`。

`.vault-meta/` 是机制 2、3、4 的共享 gate。删除它会同时关闭三者，不只是关闭其中一个。

如果要一次性关闭 setup 型 DragonScale 检测：

```bash
rm -rf .vault-meta
```

这不会删除正常 wiki 内容，也不会删除 fold 页面或已有 `address:` 字段。以后想恢复时重新运行：

```bash
bash bin/setup-dragonscale.sh
```
