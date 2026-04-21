---
name: folio-view-component-migration-from-cells
description: >-
  Migrates Trailblazer Cells (Cell::ViewModel) to ViewComponent in Folio: path and
  API mapping, cell( → render, model/options → initialize, engine CHANGELOG.
  Use when replacing `*Cell` with `*Component` or updating `cell(` call sites.
  Pair with the folio-view-component skill for generators, BEM, Stimulus, and tests.
---

# Trailblazer Cells → ViewComponent (Folio)

> **Path resolution:** This skill references Folio repo files (e.g. `docs/components.md`).
> In the Folio gem itself, use paths as-is. In a host app, resolve from the gem
> root: `bundle show folio`.

## Prerequisites

1. Follow **[`.skills/folio-view-component/SKILL.md`](../folio-view-component/SKILL.md)** for generators, base classes, BEM, Stimulus helpers, Slim/Sass/JS layout, and tests — this skill only covers the **cell-specific delta**.
2. **Read [`docs/components.md`](docs/components.md)** in the repo (open the file; do not rely on memory alone).

## When to apply

- Renaming or replacing **`SomethingCell`** with **`SomethingComponent`**
- Moving templates from **`app/cells/...`** to **`app/components/...`**
- Replacing **`cell("folio/...", model, **opts)`** (typical in views; sometimes **`helpers.cell`** from a ViewComponent) with **`render(SomeComponent.new(...))`**

## Cell → component mapping

| Cell | Component |
|------|-----------|
| `Folio::Console::Ui::FlagCell` | `Folio::Console::Ui::FlagComponent` |
| `app/cells/folio/console/ui/flag_cell.rb` | `app/components/folio/console/ui/flag_component.rb` |
| `app/cells/folio/console/ui/flag/show.slim` | `app/components/folio/console/ui/flag_component.slim` |

Default ViewComponent template is the underscored component name (**`flag_component.slim`**), not **`show.slim`**, unless you override **`template_name`** (avoid unless necessary).

**Base class:** map **`Folio::ApplicationCell`** / **`Folio::ConsoleCell`** to the same layer as in folio-view-component (`Folio::ApplicationComponent` vs `Folio::Console::ApplicationComponent` vs host **`ApplicationComponent`**).

## API differences (Cells → ViewComponent)

- **`model` / `options`** → explicit **`initialize(...)`** with keyword arguments; replace **`options[:foo]`** with instance state from **`initialize(foo:)`** defaults.
- **`show`** branching → **`render?`**, **`before_render`**, or template conditionals (preserve UX).
- **Call sites:** in views/helpers/cells, usual API is **`cell("…")`** → **`render(Namespace::MyComponent.new(...))`**. Inside a ViewComponent, **`helpers.cell`** → **`helpers.render`** / **`render`** per patterns in the same directory (see folio-view-component).

## Assets

Move cell JS/Sass into the **component colocated** paths; update **`//= require`** (or pack tags) and **`package.json`** Standard **ignore** if paths change. Details: folio-view-component + folio-stimulus.

## Tests

Replace **`Cell::TestCase`** with **`Folio::ComponentTest`** / **`Folio::Console::ComponentTest`**; assert rendered output; one **`render_inline`** per test. Full rules: folio-view-component.

## Cleanup & host apps

- Remove cell Ruby, templates, cell tests, obsolete requires.
- Grep **`cell(`**, **`helpers.cell`**, **`*Cell`** constants.
- **Folio engine:** removing or replacing anything under **`app/cells/folio/`** requires **`CHANGELOG.md`** (Unreleased or versioned) **and** **`UPGRADING.md`** — host apps may call **`cell("folio/...")`**, override paths, or depend on old CSS/JS.

## Migration checklist

- [ ] Followed **folio-view-component** + read **docs/components.md**
- [ ] Generated component (`rails generate folio:component …` per folio-view-component)
- [ ] Path/class/table above satisfied; **`initialize`** / **`render?`** as needed
- [ ] All **`cell(`** / **`helpers.cell`** → **`render(...Component.new(...))`**
- [ ] **Folio engine:** **CHANGELOG** + **UPGRADING** for Folio cell API changes
- [ ] Tests migrated; RuboCop + slim-lint + StandardJS on touched files

## Pitfalls

- **Concept cells** — map to one or more components with clear state; copy needed behavior from **`Folio::ApplicationCell`** into the component or a concern, not the whole cell stack.
- **Many `render :_partial`** — fold into one Slim template or child components / **slots** (folio-view-component).
- **Stimulus `inline: true`** on the root — see **folio-stimulus**.

## Reference

- **`app/lib/folio/application_cell.rb`** vs **`Folio::ApplicationComponent`**
- Example: catalogue cells → **`Folio::Console::CatalogueComponent`** and nested components under **`app/components/folio/console/`**
