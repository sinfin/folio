---
name: folio-scss
description: >-
  Sass/SCSS styling conventions for Folio components: BEM nesting with &,
  colocated component stylesheets, scoping rules, and avoiding cross-component
  styling. Use when writing or editing .sass/.scss files, styling ViewComponents,
  or when the user asks about CSS/Sass conventions in Folio.
---

# Sass styling (Folio)

## Styles belong on components

Almost all styles should live in **colocated component stylesheets** (`_component.sass` next to the Ruby/Slim file). Standalone stylesheets outside `app/components` should be rare — reserved for global resets, variables, or third-party overrides.

## BEM nesting

Use the block class as the root selector, then **`&__element`** and **`&--modifier`** nesting:

```sass
.f-c-ui-button
  display: inline-flex
  align-items: center

  &__icon
    margin-left: -4px

  &__label
    font-weight: $font-weight-bold

  &--primary
    background: $blue
    color: $white

  &--primary &__label
    text-transform: uppercase
```

- **One root selector** per component file — the BEM block.
- **Elements** (`&__`) and **modifiers** (`&--`) are always nested under the block.
- For modifier + element combinations, use `&--modifier &__element` (see examples above).

## Don't style child components

A component's stylesheet must only target **its own** BEM block. Never reach into a child component's classes:

```sass
// Bad — parent styling a child component's internals
.f-c-catalogue
  .f-c-ui-button
    margin-top: 8px

  .f-c-ui-button__label
    color: red

// Good — pass a class_name or modifier to the child component
.f-c-catalogue
  &__action-button
    margin-top: 8px
```

If a child needs to look different in a specific context, pass attributes to it (e.g. `class_name:`, a modifier, or a variant) and let the child style itself.

## Responsive styles

- **Prefer container queries** over media queries. Components are often rendered in varying contexts (full-width page vs narrow sidebar) where viewport width is irrelevant — container queries adapt to the actual available space.
- Use **media queries** only for truly viewport-dependent behavior (e.g. sticky headers, full-screen overlays, print styles).

```sass
// Good — adapts to the component's container width
.m-card
  container-type: inline-size

  &__grid
    display: grid
    grid-template-columns: 1fr

    @container (min-width: 600px)
      grid-template-columns: 1fr 1fr

// Acceptable — viewport-level concern
.f-c-layout
  +media-breakpoint-down(sm)
    padding: 0
```

## Variables and utilities

- Use existing variables (`$blue`, `$gray`, `$border-radius`, `$transition-base`, `$font-weight-bold`, etc.) — don't hardcode values.
- Use `px-to-rem()` for pixel-based sizing.
- Use Bootstrap breakpoint mixins (`+media-breakpoint-down(sm)`) only for viewport-level concerns.
- Use `$f-c-state-colors` map and `@each` for color variants when applicable.

## File format

- Both **indented Sass** (`.sass`) and **SCSS** (`.scss`) are used — match the convention of sibling components in the same directory.
- One blank line between element/modifier blocks for readability.

## Quality gates

Sass files are compiled as part of the asset pipeline. Check for compilation errors after edits.

## Reference

- BEM naming rules: `AGENTS.md` (View Components section)
- Component structure: [`.skills/folio-view-component/SKILL.md`](../folio-view-component/SKILL.md)
- Examples: `app/components/folio/console/ui/*_component.sass`
