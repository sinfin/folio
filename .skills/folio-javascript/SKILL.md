---
name: folio-javascript
description: >-
  JavaScript conventions for Folio: ES6+, StandardJS linting, DOM APIs, Folio.Api
  fetch wrappers, debounce/throttle, flash events, and when to use Stimulus.
  Use when writing or editing .js files, adding behavior to components, or when
  the user asks about JavaScript patterns in Folio.
---

# JavaScript (Folio)

## Language and style

- Use **modern ES6+**: `const`/`let`, arrow functions, template literals, destructuring, `async`/`await`.
- No `var`, no jQuery in new code.
- Lint with **`npx standard --fix <path>`** (StandardJS — no semicolons, 2-space indent). See `AGENTS.md`.

## When to use Stimulus

For any **interactive component behavior** (click handlers, form inputs, toggling classes, AJAX actions), use a **Stimulus controller** rather than standalone JS. See [`.skills/folio-stimulus/SKILL.md`](../folio-stimulus/SKILL.md).

Plain JS (without Stimulus) is appropriate for:
- Global utilities and helpers under `app/assets/javascripts/folio/`
- One-off scripts that don't belong to a component
- Library wrappers and polyfills

## DOM APIs

Use native DOM — no jQuery:

- `document.querySelector` / `querySelectorAll`
- `element.closest`, `classList`, `dataset`
- `addEventListener` / `removeEventListener` (in Stimulus controllers, prefer `data-action` instead — see folio-stimulus)
- `insertAdjacentHTML`, `replaceWith`, `remove`

## HTTP / AJAX

Use `window.Folio.Api` (`app/assets/javascripts/folio/api.js`) instead of raw `fetch` or `$.ajax`:

```javascript
window.Folio.Api.apiPatch(url, data).then((res) => {
  // res.data available; flash already handled via flashMessageFromMeta
}).catch((res) => {
  // res.message contains the error
})
```

Available: `apiGet`, `apiPost`, `apiPatch`, `apiPut`, `apiDelete`. They handle CSRF, JSON serialization, and automatically dispatch `folio:flash` from `meta.flash` — **do not** call `flashMessageFromMeta` again in `.then`.

## Flash messages

Dispatch `folio:flash` events — do **not** call `window.FolioConsole.Ui.Flash.*` directly:

```javascript
document.dispatchEvent(new CustomEvent('folio:flash', {
  bubbles: true,
  detail: { flash: { content: 'Saved', variant: 'success' } }
}))
```

Variants: `success`, `danger`, `info`, `loader`. Listener: `app/components/folio/console/ui/flash_component.js`.

## Custom events

- Prefer `dispatchEvent(new CustomEvent('name', { bubbles: true, detail }))`.
- In Stimulus controllers, use `this.dispatch('eventName', { detail })` for controller-to-controller communication.

## Cleanup — unbind and destroy

When adding event listeners, plugin instances, or observers, **always** provide a way to tear them down. Leaking listeners causes memory leaks and double-firing bugs.

- In Stimulus controllers, use `disconnect()` to remove anything set up in `connect()`.
- In plain JS utilities, expose **`bind` / `unbind`** (or similar) functions:

```javascript
window.Folio.MyFeature = {
  bind (container) {
    container.addEventListener('click', this.handler)
  },

  unbind (container) {
    container.removeEventListener('click', this.handler)
  }
}
```

This applies to `addEventListener`, `MutationObserver`, `IntersectionObserver`, `ResizeObserver`, `setInterval`, third-party plugin instances, etc.

## Global namespace

When exporting functionality for the rest of the app, use the **global namespace** — not ES module exports (the asset pipeline doesn't use a module bundler):

```javascript
window.Folio = window.Folio || {}
window.Folio.Confirm = { confirm (callback) { /* ... */ } }

// Host app
window.MyApp = window.MyApp || {}
window.MyApp.Analytics = { track (event) { /* ... */ } }
```

Namespace under `window.Folio.*` for engine code, `window.FolioConsole.*` for console-specific engine code, and `window.<AppName>.*` for host app code.

## Debounce and throttle

For rapidly firing callbacks (scroll, resize, input, mousemove), **always** debounce or throttle:

- **`window.Folio.debounce(fn, wait = 150, immediate = false)`** — delays execution until `wait` ms after the last call. Use for search inputs, resize layout recalculations.
- **`window.Folio.throttle(fn, delay = 100)`** — executes at most once per `delay` ms. Use for scroll handlers, drag tracking.

```javascript
this.onScroll = window.Folio.throttle(() => { this.handleScroll() }, 100)
this.onResize = window.Folio.debounce(() => { this.handleResize() }, 200)
```

Source: `app/assets/javascripts/folio/debounce.js`, `app/assets/javascripts/folio/throttle.js`.

## Reference

- `app/assets/javascripts/folio/api.js` — API fetch wrappers
- `app/assets/javascripts/folio/debounce.js`, `throttle.js` — timing utilities
- `app/components/folio/console/ui/flash_component.js` — flash event listener
- Stimulus conventions: [`.skills/folio-stimulus/SKILL.md`](../folio-stimulus/SKILL.md)
