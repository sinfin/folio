---
name: folio-stimulus
description: >-
  Folio Stimulus conventions: controller registration, StimulusHelper data
  attributes, values/targets/actions, and controller file placement. Use when
  adding JavaScript behavior to a Folio component, wiring data-controller /
  data-action / data-target, using StimulusHelper in Slim, or writing a new
  Stimulus controller in Folio or a host app.
---

# Stimulus (Folio)

## Prerequisites

Follow **[`.skills/folio-javascript/SKILL.md`](../folio-javascript/SKILL.md)** for ES6+ conventions, StandardJS linting, `Folio.Api`, flash events, debounce/throttle, and DOM APIs — this skill only covers the **Stimulus-specific** layer.

## When to use

- Adding interactive behavior to a ViewComponent
- Wiring `data-controller`, `data-action`, `data-target` in Slim templates
- Writing or editing a `*_component.js` Stimulus controller

## Controller registration

Place the JS file **beside the component** (`app/components/.../my_component.js`).
Register with `window.Folio.Stimulus.register`:

```javascript
window.Folio.Stimulus.register('f-c-my-feature', class extends window.Stimulus.Controller {
  static values = { url: String }
  static targets = ['input']
  static classes = ['active']

  connect () { /* ... */ }
})
```

Require the file from the appropriate manifest (e.g. `folio/console/base.js` for console components, or the app's JS entrypoint).

## Controller naming

The controller identifier **matches the BEM block** of the component:

| Component class | BEM block / controller id |
|-----------------|---------------------------|
| `Folio::Console::Ui::BooleanToggleComponent` | `f-c-ui-boolean-toggle` |
| `Folio::Console::CatalogueComponent` | `f-c-catalogue` |
| `MyApp::Blog::PostComponent` | `m-blog-post` |

See `AGENTS.md` (View Components) for the full BEM derivation rules.

## StimulusHelper — Ruby/Slim data attributes

`Folio::StimulusHelper` (`app/helpers/folio/stimulus_helper.rb`) is included in `Folio::ApplicationComponent` and descendants.

### Root element — `stimulus_controller`

Call on the **root element's** `data` hash. This sets `@stimulus_controller_name` for child helpers.

```slim
.my-block data=stimulus_controller("m-my-block",
                                    values: { url: some_url },
                                    action: { click: "onClick" },
                                    classes: %w[active],
                                    outlets: %w[f-c-other])
```

**Do not** pass `inline: true` on the primary root — it skips setting `@stimulus_controller_name` and breaks child helpers.

### Children — `stimulus_target`, `stimulus_action`

After the root sets `@stimulus_controller_name`, children use short-form helpers:

```slim
input data=stimulus_target("input")
button data=stimulus_action(click: "submit")
a data=stimulus_action({ click: "open" }, { id: item_id })   / action + params
```

### Multiple controllers — `stimulus_merge_data`

When one node needs data from multiple controllers (e.g. a lightbox + a feature controller):

```slim
.root data=stimulus_merge_data(stimulus_controller("m-gallery"),
                                stimulus_lightbox)
```

`stimulus_merge_data` concatenates `controller` and `action` strings; other keys are merged.

### `inline: true`

Use **only** when the hash is merged into a node that must **not** own the controller name — e.g. one-off utility controllers (`stimulus_lightbox`, `stimulus_tooltip`, `stimulus_scroll_link`) on a parent that already registered its own controller. The primary feature controller should **never** use `inline: true`.

## Built-in utility helpers

`StimulusHelper` provides ready-made helpers for common patterns:

| Helper | Controller | Typical use |
|--------|-----------|-------------|
| `stimulus_lightbox` | `f-lightbox` | Image gallery overlay |
| `stimulus_tooltip(title, ...)` | `f-tooltip` | Hover/click tooltips |
| `stimulus_modal(open:)` | `f-modal` | Dialog/modal windows |
| `stimulus_modal_toggle(target)` | `f-modal-toggle` | Open/close a modal |
| `stimulus_scroll_link(selector)` | `f-scroll-link` | Smooth-scroll to element |
| `stimulus_click_trigger(target)` | `f-click-trigger` | Proxy click to another element |

All utility helpers use `inline: true` internally — they are designed to be merged alongside a primary controller.

## Events

- **Prefer `data-action`** over `addEventListener` / `removeEventListener`. Stimulus actions are declarative, automatically cleaned up on `disconnect`, and self-documenting in the markup.
- **Global events** (window resize, scroll, keydown, etc.) — use `@window` or `@document` descriptors instead of manual listeners:

  ```slim
  div data=stimulus_action("resize@window": "onResize", "keydown@window": "onKeydown")
  ```

- **Controller-to-controller communication** — use `this.dispatch('eventName', { detail })` which bubbles by default. Parent controllers listen via `data-action="child-controller:event-name->parent#handler"`.
- Use `connect()` / `disconnect()` for setup/teardown — no global `$(document).on`.

## Pitfalls

- **`inline: true` on the primary controller** — `@stimulus_controller_name` is not set; `stimulus_target` / `stimulus_action` on children will fail or bind to the wrong controller.
- **Eval order in Slim** — the root `data=` hash that calls `stimulus_controller` must evaluate before sibling markup that uses `stimulus_target`. ViewComponent root attributes typically evaluate first.
- **Blocks / `instance_eval`** — setting `@stimulus_controller_name` affects `stimulus_action` inside host-app blocks rendered in the same component. Scope Stimulus-heavy markup into a dedicated child component if this collides.

## Reference

- `app/helpers/folio/stimulus_helper.rb` — all helper methods and signatures
- JavaScript conventions: [`.skills/folio-javascript/SKILL.md`](../folio-javascript/SKILL.md)
- Examples: `app/components/folio/console/ui/boolean_toggle_component.*`, `app/components/folio/console/catalogue_component.*`
