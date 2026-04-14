---
name: folio-slim
description: >-
  Slim template formatting and best practices for Folio components and views.
  Use when writing or editing .slim templates, reviewing Slim formatting,
  or when the user asks about Slim conventions, multi-line attributes, or
  template structure in Folio.
---

# Slim templates (Folio)

## Avoid inline Ruby

Don't put logic in `- ` lines. Extract a **private** component method and call it with `=`:

```slim
/ Bad
- classes = ["foo", ("bar" if @active)].compact.join(" ")
div class=classes

/ Good — move to a component method
div class=wrapper_class_name
```

## Multi-line attributes

When an element has **multiple attributes**, use bracket syntax **without a space** before `[`:

```slim
a[
  class="f-c-ui-button"
  class="f-c-ui-button--primary"
  href=@url
  data=stimulus_action(click: "onClick")
]
```

For a **single short attribute**, keep it inline:

```slim
a href="#section"
span.badge data-count=@count
```

## Multiple `class` attributes

Use **separate `class` attributes** instead of string concatenation or array joining:

```slim
/ Good
div[
  class="f-c-ui-alert"
  class="f-c-ui-alert--danger"
  class=@class_name
]

/ Bad
div class="f-c-ui-alert f-c-ui-alert--danger #{@class_name}"
```

Slim merges multiple `class` attributes automatically. `nil` values are safely ignored.

## Shorthand classes

Use `.class-name` shorthand on `div` (tag is implicit) and `tag.class-name` on other elements:

```slim
.f-c-ui-modal__body
  span.f-c-ui-modal__label = @label
  button.f-c-ui-modal__close type="button"
```

When an element already uses bracket syntax with multiple `class` attributes, **don't mix** `.shorthand` — use `class` attributes consistently:

```slim
/ Good — all classes as attributes
li[
  class="nav-item"
  class="f-c-ui-tabs__nav-item"
  hidden=tab[:hidden]
]

/ Bad — mixing shorthand with class attributes
li.nav-item[
  class="f-c-ui-tabs__nav-item"
  hidden=tab[:hidden]
]
```

## Boolean attributes

Pass the value directly — Slim omits the attribute when `nil` or `false`:

```slim
input disabled=@disabled
button hidden=@hidden
```

## Output

- `=` for escaped Ruby output (default, safe)
- `'` at line start for a trailing space (e.g. between inline elements)
- **Avoid `==`** (unescaped output). Prefer `= safe_join(...)` or `= tag.span(...)` to build HTML safely:

```slim
/ Bad — unescaped, risky
== [t(".line_one"), t(".line_two")].join("<br>")

/ Good — safe_join handles html_safe pieces
= safe_join([t(".line_one"), t(".line_two")], tag.br)
```

Use `==` only when rendering a trusted `html_safe` string where no safe alternative exists.

## Keep templates short

If a template exceeds ~50 lines or has deeply nested conditionals, split into **child ViewComponents** or **slots**. The template should be mostly structure; logic belongs in component methods.

See **folio-view-component** skill for composition patterns.

## Comments

Use Slim comments (`/`) which are stripped from output. Avoid HTML comments (`/!`) unless they must appear in the rendered page.

## Dynamic tag splat

Use `*method` to build a tag from a hash (tag name, attributes) returned by a component method:

```slim
*tag
  = @label
```

Where `tag` is a component method returning e.g. `{ tag: :a, href: @url, class: "btn" }`.

## Quality gates

`slim-lint <path>` on all Slim files (see `AGENTS.md`).

## Reference

- Examples: `app/components/folio/console/ui/*_component.slim`
- ViewComponent conventions: [`.skills/folio-view-component/SKILL.md`](../folio-view-component/SKILL.md)
