# 方法论模式指南 — v1.8.0

**状态：** 上游 v1.8.0 GA（2026-05-17）  
**范围：** 为 vault 选择组织方法，并让新页面按该方法路由  
**当前迁移：** 本文为 `codex-obsidian` 的中文版本

---

## TL;DR

选择最符合你思考方式的模式：

| 你的思考方式 | 选择 |
|---|---|
| 主题簇 + 跟随链接导航 | **LYT** |
| 活跃项目、持续职责、参考资料要分清 | **PARA** |
| 原子观点、唯一 ID、高密度链接 | **Zettelkasten** |
| 不想使用方法论，沿用默认结构 | **Generic** |

交互式设置：

```bash
bash bin/setup-mode.sh
```

非交互式设置：

```bash
bash bin/setup-mode.sh --mode lyt
```

设置后，`wiki-ingest`、`save`、`autoresearch` 会在归档新页面前读取当前模式。已有文件不会自动移动；模式只影响之后生成的新页面。

---

## 为什么需要方法论模式

上游 v1.7 解决了四类优先问题：基础层对齐、默认 transport、混合检索、多写者安全。方法论支持被放到 v1.8。

原因是：知识库不是只有“保存文件”这一个问题。长期使用后，真正决定体验的是页面应该放在哪里、如何连接、如何复查、如何避免结构膨胀。

v1.8 把方法论从“用户自己记得怎么归档”变成“skills 调用统一 router”。这样新页面归档不再散落在各个 skill 里。

---

## 四种模式

### Generic（默认）

**哲学：** 不强加组织方法。与早期默认行为一致。

**归档约定：**

- `wiki/sources/<slug>.md`：摄取的 source 文档；
- `wiki/entities/<Name>.md`：人物、组织、产品等实体；
- `wiki/concepts/<Name>.md`：概念、框架和主题；
- `wiki/sessions/<date>-<topic>.md`：通过 `/save` 保存的会话笔记。

**适用：**

- 从旧版本迁移，希望行为尽量不变；
- 还没决定知识库方法论；
- 已经有自己的组织直觉，只需要较轻的默认结构。

**优点：** 学习成本低、灵活、符合默认肌肉记忆。  
**缺点：** 在大型 vault 中容易扩散，需要用户自己维持结构。

---

### LYT（Linking Your Thinking）

**哲学：** 组织原语是 MOC（Map of Content）。原子笔记尽量扁平存放，MOC 负责把它们组织成主题簇。导航靠链接，不靠文件夹。

**归档约定：**

- `wiki/mocs/<topic>-moc.md`：某个主题簇的 MOC；
- `wiki/notes/<atomic-note>.md`：所有原子笔记；
- 每篇原子笔记 frontmatter 至少有一个 `mocs:`；
- 新 ingest 进入 `wiki/notes/`，同时更新相关 MOC。

**模板：**

- `skills/wiki-mode/templates/lyt/moc-template.md`
- `skills/wiki-mode/templates/lyt/atomic-template.md`

**适用：**

- 中大型知识库（100+ notes）；
- 你习惯按概念簇和知识图谱思考；
- 你已经使用 LYT，或希望开始使用。

**优点：** 随规模增长越来越有价值；导航路径丰富；结构显式。  
**缺点：** 需要持续维护 MOC；扁平 notes 文件夹可能依赖搜索体验。

---

### PARA

**哲学：** 按可行动性组织，而不是按主题组织。

- Projects：有目标和截止时间的活跃项目；
- Areas：持续负责、没有明确结束点的领域；
- Resources：按主题保存的参考资料；
- Archives：完成、暂停或不再活跃的内容。

**归档约定：**

- `wiki/projects/<project-name>/<note>.md`
- `wiki/projects/inbox/<note>.md`
- `wiki/areas/<area-name>/<note>.md`
- `wiki/resources/<topic>/<note>.md`
- `wiki/resources/incoming/<note>.md`
- `wiki/resources/people/<Name>.md`
- `wiki/resources/concepts/<Name>.md`
- `wiki/archives/<year>/<note>.md`

**模板：**

- `skills/wiki-mode/templates/para/project-template.md`
- `skills/wiki-mode/templates/para/area-template.md`
- `skills/wiki-mode/templates/para/resource-template.md`

**适用：**

- 项目和行动很多的知识工作者；
- GTD 或 Building a Second Brain 使用者；
- 需要明确区分“正在推进”和“只是参考”的人。

**优点：** 项目生命周期清晰；活跃工作和资料分离。  
**缺点：** 需要定期 review，把完成项目移入 archives；incoming 区域需要处理。

---

### Zettelkasten

**哲学：** 原子笔记、唯一 ID、密集双向链接。每篇笔记只表达一个观点。组织通过 ID 和链接完成，而不是文件夹。

**归档约定：**

- `wiki/<YYYYMMDDHHMMSSffffff>-<slug>.md`：扁平放在 `wiki/` 根目录；
- frontmatter 包含 `id:`、可选 `parent_id:`、可选 `child_ids:`；
- 不使用子目录；
- 正文通过 `parent_id`、`child_ids` 和 `[[ID]]` 形成网络。

**模板：**

- `skills/wiki-mode/templates/zettel/atomic-template.md`

**适用：**

- 学术研究者；
- 长期构建永久知识资产的人；
- 读过或实践《How to Take Smart Notes》的人；
- 能接受较高纪律要求的人。

**优点：** 链接密度高；促进原子化思考；适合多年演化。  
**缺点：** 学习曲线最陡；扁平文件列表不直观；ID 不如命名路径好记。

---

## 模式如何影响其他 skills

集成是自动的。设置模式后，以下 skills 都调用同一个 router：

| Skill | 本职 | 模式影响 |
|---|---|---|
| `wiki-ingest` | 归档 source/entity/concept 页面 | router 决定目标目录 |
| `save` | 保存当前会话 | router 决定保存到 session、note、project inbox 或 zettel |
| `autoresearch` | 保存研究综合页 | router 决定 topic MOC、resources、concepts 或 zettel |

单一真相来源：

```bash
python3 scripts/wiki-mode.py route <type> "<name>"
```

skills 不应该各自手写路径逻辑。

---

## 以后切换模式

切换模式是安全的，但不会自动迁移已有文件：

1. 运行 `bash bin/setup-mode.sh`，或使用 `--mode <new-mode>`；
2. 新模式写入 `.vault-meta/mode.json`；
3. 已有文件保持原位；
4. 新文件按新模式归档；
5. 如果需要，手工用文件管理器或 `git mv` 迁移旧文件。

不做自动迁移的原因：wiki 存的是你的思考。自动重写路径可能破坏 wikilinks、丢信息或制造意外。手动迁移能让你明确判断哪些内容适合新方法论。

切换到 LYT 后，建议运行：

```text
lint the wiki
```

用来找出适合纳入 MOC 的孤儿页。

---

## 模式配置文件

当前模式写在：

```text
.vault-meta/mode.json
```

该文件默认 gitignored，因为它被视为本机运行态配置。如果你想在多机器或协作者之间共享模式选择：

```bash
git add -f .vault-meta/mode.json
git commit -m "chore: declare vault mode as <mode>"
```

schema 示例：

```json
{
  "schema_version": 1,
  "mode": "lyt|para|zettelkasten|generic",
  "configured_at": "2026-05-17T00:00:00Z",
  "config": {
    "lyt": {"moc_folder": "wiki/mocs/", "notes_folder": "wiki/notes/"},
    "para": {"projects_folder": "...", "areas_folder": "...", "resources_folder": "...", "archives_folder": "..."},
    "zettelkasten": {"id_format": "YYYYMMDDHHMMSSffffff", "no_folders": true, "root_folder": "wiki/"},
    "generic": {"sources_folder": "wiki/sources/", "entities_folder": "wiki/entities/", "concepts_folder": "wiki/concepts/", "sessions_folder": "wiki/sessions/"}
  }
}
```

`config` 总是包含四种模式。真正生效的是 `mode` 字段。

---

## 什么时候不要用方法论模式

- **很小的 vault**：少于 20 篇笔记时，组织开销可能大于收益。
- **你并不在乎方法论**：那就使用 Generic。
- **跨项目共享的个人 vault**：项目内的 router 只应该影响项目自己的 `wiki/`，不要替你改写个人 vault 的组织原则。

---

## 后续路线

方法论模式解决了上游 v1.8 的核心缺口。剩余方向：

| 方向 | 状态 | 后续 |
|---|---|---|
| 复利 wiki primitive | 已领先 | 继续维护 |
| 多写者安全 | 已有核心机制 | 继续强化 |
| 检索架构 | 已有免费 tier | 增强 dense vector 和 rerank |
| 开放许可 | MIT | 保持 |
| 方法论支持 | v1.8 已加入 | 扩展 review |
| 派生输出 | 未完成 | v2.0 `wiki-derive` |
| GUI / 安装体验 | 未完成 | v2.5+ Community Plugin |

---

## 交叉引用

- [`skills/wiki-mode/SKILL.md`](../skills/wiki-mode/SKILL.md)
- [`scripts/wiki-mode.py`](../scripts/wiki-mode.py)
- [`bin/setup-mode.sh`](../bin/setup-mode.sh)
- [`tests/test_wiki_mode.py`](../tests/test_wiki_mode.py)
- [`docs/compound-vault-guide.md`](compound-vault-guide.md)
