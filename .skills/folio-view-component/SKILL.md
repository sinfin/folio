---
name: folio-view-component
description: >-
  Develops and maintains Folio ViewComponents: generators, BEM, Slim, Stimulus
  data attributes, colocated assets, tests, and composition. Use when building
  or editing UI in app/components, adding Stimulus to a component, writing
  component tests, or when the user asks for ViewComponent / frontend component
  patterns in Folio or a host app on Folio.
---

# ViewComponent development (Folio)

> **Path resolution:** This skill references Folio repo files (e.g. `docs/components.md`).
> In the Folio gem itself, use paths as-is. In a host app, resolve from the gem
> root: `bundle show folio`.

## When to use

- New or refactored UI in **`app/components/**`**
- Wiring **Stimulus** (`data-controller`, targets, actions) on component markup
- **Slim + Sass** for a feature; BEM class names aligned with the component
- **Tests** for components (`render_inline`, selectors)
- Reviewing whether to use a **slot**, child `render`, or a partial

## Required reading

**Open and use [`docs/components.md`](docs/components.md)** in this repo (directory layout, naming, BEM, Stimulus placement, testing, slots vs `html_safe`). Do not rely on memory alone.

**JavaScript behavior:** follow [`.skills/folio-javascript/SKILL.md`](../folio-javascript/SKILL.md) for ES6+ conventions, `Folio.Api`, and flash events. For Stimulus controllers, see [`.skills/folio-stimulus/SKILL.md`](../folio-stimulus/SKILL.md). For migrating legacy jQuery/IIFE scripts, see [`.skills/folio-stimulus-migration-from-legacy-js/SKILL.md`](../folio-stimulus-migration-from-legacy-js/SKILL.md).

## Generators

- **Always** create new components with the Folio generator — do not copy-paste empty classes by hand.
- **Folio engine** (`Folio::…` namespace): leading slash:

  `rails generate folio:component /folio/console/ui/example`

- **Host app** components: omit the app namespace when using a relative path; the generator auto-prefixes it (e.g. in MyProject, use `rails generate folio:component footer/menu` for `MyProject::Web::Footer::MenuComponent`). Use a leading slash only when specifying the full namespace explicitly.

See **`AGENTS.md`** (Generators + View Components) for the slash rule and examples.

## Base classes

| Context | Inherit |
|---------|---------|
| Folio engine, console admin | `Folio::Console::ApplicationComponent` |
| Folio engine, non-console | `Folio::ApplicationComponent` |
| Host app (typical) | App’s **`ApplicationComponent < Folio::ApplicationComponent`** (and console analogue if applicable) — match sibling components; do not subclass `Folio::ApplicationComponent` directly if the app defines its own base. |

Generator parent is configurable via **`folio_component_generator_parent_component_class_name_proc`**.

## Initialize

- Components **should define `initialize`** most of the time — even an empty `def initialize; end` is preferable to omitting it.
- **Required** when the component inherits directly from `Folio::ApplicationComponent` / `Folio::Console::ApplicationComponent` (or the host app's `ApplicationComponent`).
- **Skippable** only in rare cases where a shared ancestor or concern already defines `initialize` for this component family.

## Markup & styling

- **Templates:** Slim; keep templates thin; logic in the component class (mostly **`private`** methods). Follow [`.skills/folio-slim/SKILL.md`](../folio-slim/SKILL.md) for formatting conventions (multi-line attributes, multiple `class` attrs, avoiding inline Ruby and `==`).
- **BEM block** from the component class name (`Folio::Console::…` → **`f-c-…`** prefix). Elements **`__`**, modifiers **`--`**. See `AGENTS.md` View Components section.
- **Styles:** colocated **`_component.sass`** (or `.scss`) next to the Ruby/Slim file; scope to the block. Follow [`.skills/folio-scss/SKILL.md`](../folio-scss/SKILL.md) for BEM nesting, scoping rules, and avoiding cross-component styling.
- **Composition:** prefer **`render ChildComponent.new(...)`** or **slots** over subclassing another ViewComponent that has its own template. Avoid passing large HTML strings / `html_safe` where a slot fits.

## Stimulus

Full conventions in **[`.skills/folio-stimulus/SKILL.md`](../folio-stimulus/SKILL.md)**. Key points for component markup:

- `StimulusHelper` is included via `Folio::ApplicationComponent` (and app `ApplicationComponent` if it inherits Folio).
- Root `data` hash: **`stimulus_controller`** (sets `@stimulus_controller_name`); **`stimulus_merge_data`** for multiple controllers.
- Children: **`stimulus_target`** / **`stimulus_action`** — only after the root sets `@stimulus_controller_name`. **Do not** use `inline: true` on the primary controller.
- JS file beside the component; register with **`window.Folio.Stimulus.register(...)`**; wire into the asset manifest.

## Rendering

- From views/controllers: **`render MyComponent.new(foo: bar)`** (or helper wrappers your app uses).
- From inside a ViewComponent: **`render OtherComponent.new(...)`** or **`helpers.render(...)`** as in nearby Folio examples.

## Testing

- Subclass **`Folio::ComponentTest`** or **`Folio::Console::ComponentTest`** (`test/test_helper_base.rb`).
- Assert on **rendered output** (`render_inline`, `assert_selector`, `rendered_content`) — not isolated calls to private methods.
- **One `render_inline` per test**; extra cases → separate tests.
- Path: **`test/components/.../name_component_test.rb`**.

## Quality gates

After edits: **`rubocop --autocorrect-all`** on Ruby, **`slim-lint`** on Slim, **`npx standard --fix`** on component JS (`AGENTS.md`).

## Quick reference

- `app/helpers/folio/stimulus_helper.rb` — `stimulus_controller`, `stimulus_data`, `stimulus_merge_data`, …
- `docs/components.md` — full narrative + diagram
- Example console components: `app/components/folio/console/ui/*_component.rb`
