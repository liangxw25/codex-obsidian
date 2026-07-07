# Wiki Layout Policy

`wiki` uses a single core layout by default. Do not create extra folders from
use-case labels such as Website, Repository, Business, Personal, Research, or
Book/Course.

Those labels were useful as prompts for describing a vault's purpose, but they
were not connected to the real filing router. Creating folders from them
produced isolated `_index.md` pages that other skills did not write into.

---

## Core Layout

Create and maintain only the folders that current skills actually use:

```
vault/
├── .raw/
│   ├── articles/
│   ├── transcripts/
│   ├── images/
│   └── data/
├── wiki/
│   ├── index.md
│   ├── log.md
│   ├── hot.md
│   ├── overview.md
│   ├── sources/
│   │   └── _index.md
│   ├── entities/
│   │   └── _index.md
│   ├── concepts/
│   │   └── _index.md
│   ├── domains/
│   │   └── _index.md
│   ├── questions/
│   │   └── _index.md
│   ├── comparisons/
│   │   └── _index.md
│   ├── sessions/
│   │   └── _index.md
│   ├── canvases/
│   └── meta/
│       └── _index.md
├── .vault-meta/
├── .obsidian/
└── AGENTS.md
```

## Filing Rules

The default `.vault-meta/mode.json` mode is `generic`.

Under `generic`, new pages are routed as follows:

| Content | Destination |
|---|---|
| Raw source summaries | `wiki/sources/` |
| Entities | `wiki/entities/` |
| Concepts | `wiki/concepts/` |
| Top-level topic areas | `wiki/domains/` |
| Saved analysis / questions | `wiki/questions/` |
| Session saves | `wiki/sessions/` |
| Dashboards, reports, conventions | `wiki/meta/` |
| Obsidian canvases | `wiki/canvases/` |

If a user wants a methodology-specific filing system, use `wiki-mode`:

- `generic`: `wiki/sources/`, `wiki/entities/`, `wiki/concepts/`, `wiki/sessions/`
- `lyt`: `wiki/notes/` plus MOCs in `wiki/mocs/`
- `para`: `wiki/projects/`, `wiki/areas/`, `wiki/resources/`, `wiki/archives/`
- `zettelkasten`: flat timestamped notes under `wiki/`

`wiki-mode` is the only mechanism that should change new-page filing paths.

## What Not To Create

Do not scaffold use-case-only folders unless a future router explicitly writes
to them:

- `wiki/pages/`, `wiki/structure/`, `wiki/audits/`, `wiki/keywords/`
- `wiki/modules/`, `wiki/components/`, `wiki/dependencies/`, `wiki/flows/`
- `wiki/stakeholders/`, `wiki/deliverables/`, `wiki/intel/`, `wiki/comms/`
- `wiki/goals/`, `wiki/learning/`, `wiki/people/`
- `wiki/papers/`, `wiki/thesis/`, `wiki/gaps/`
- `wiki/characters/`, `wiki/themes/`, `wiki/timeline/`, `wiki/synthesis/`

These names may still appear as semantic tags, domains, or page titles. They
should not become empty physical layout folders by default.
