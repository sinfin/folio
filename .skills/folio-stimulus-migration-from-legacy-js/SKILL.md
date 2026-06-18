---
name: folio-stimulus-migration-from-legacy-js
description: >-
  Converts legacy front-end scripts (jQuery, global document listeners, IIFEs)
  to Stimulus controllers plus vanilla DOM/fetch, aligned with Folio ViewComponent
  patterns. Use when migrating jQuery handlers, `$(document).on`, CoffeeScript-era
  bundles, or ad-hoc `window.*` APIs to Stimulus; when the user asks to remove
  jQuery from a feature; or when adding behavior to Folio components.
---

# Legacy JavaScript → Stimulus (Folio)

## Prerequisites

Follow **[`.skills/folio-javascript/SKILL.md`](../folio-javascript/SKILL.md)** for ES6+ conventions, `Folio.Api`, flash events, and debounce/throttle. Follow **[`.skills/folio-stimulus/SKILL.md`](../folio-stimulus/SKILL.md)** for controller registration, naming, and `StimulusHelper` — this skill only covers the **migration-specific delta**.

## When to apply

- Replacing `window.jQuery`, `$(document).on`, delegated events, or `$.ajax`
- Moving logic from `app/assets/javascripts` IIFEs into a component-owned file
- User wants "vanilla + Stimulus" or to drop jQuery from a specific UI

## Migration steps

1. **Map scope** — Identify the smallest DOM subtree that owns the behavior (usually one ViewComponent root).
2. **Replace globals** — Remove `$(document).on` / `jQuery(function () { ... })`; use `connect` / `disconnect` and declarative `data-action` on the root or targets, or `static targets` + methods.
3. **DOM** — `Element.closest`, `querySelector` / `querySelectorAll`, `classList`, `dataset`, `addEventListener` only when Stimulus actions are insufficient (e.g. non-interaction lifecycle).
4. **AJAX** — Replace `$.ajax` / `$.get` / `$.post` with `Folio.Api` helpers (see folio-javascript skill). Update DOM with `insertAdjacentHTML`, `replaceWith`, or `Template` + `replaceChild` patterns; re-run any required init hooks (e.g. React mount helpers) explicitly.
5. **Custom events** — Prefer `dispatchEvent(new CustomEvent('name', { bubbles: true, detail }))`. If host code still uses jQuery `.on`, optionally also `window.jQuery(el).trigger('name', payload)` when `window.jQuery` exists; document payload shape (`detail` vs extra args).
6. **Overridable hooks** — If the old script exposed `window.Something.onFoo = fn`, keep a thin `window.*` namespace for app overrides but wire the controller to call it with DOM nodes, not jQuery objects.
7. **Tests** — Assert rendered `data-controller`, `data-action`, and critical targets in component tests where behavior is contractually important.
8. **Cleanup** — Remove obsolete `package.json` `standard.ignore` entries for migrated files; update `//= require` / import graph; delete dead legacy files.

## Checklist

- [ ] Followed **folio-javascript** + **folio-stimulus** skills
- [ ] jQuery removed from migrated file (unless a deliberate interop shim)
- [ ] `//= require` / import graph updated; dead legacy file deleted if fully replaced
- [ ] StandardJS clean; Slim uses helper-generated `data` where applicable

## Pitfalls

- **jQuery interop** — If host code still relies on jQuery `.on` for the same events, provide a thin shim that triggers both native and jQuery events during the transition.
- **Global state** — Legacy scripts often store state on `window.*`; move it into Stimulus `values` or controller instance state. Keep a thin `window.*` namespace only for documented host-app override hooks.

## Reference

- JavaScript conventions: [`.skills/folio-javascript/SKILL.md`](../folio-javascript/SKILL.md)
- Stimulus conventions: [`.skills/folio-stimulus/SKILL.md`](../folio-stimulus/SKILL.md)
- ViewComponent markup and structure: [`.skills/folio-view-component/SKILL.md`](../folio-view-component/SKILL.md)
- Examples: `app/components/folio/console/ui/boolean_toggle_component.*`, `app/components/folio/console/catalogue_component.*`
