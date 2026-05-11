---
name: folio-simple-form-inputs
description: >-
  Build or change Folio SimpleForm inputs and extensions: app/inputs classes,
  SimpleForm::Inputs overrides, register_stimulus wiring, input_controls,
  custom_html, standalone input JS/Sass assets, and rendered HTML tests.
---

# Folio SimpleForm Inputs

Use this when adding or changing SimpleForm input classes, input overrides, or
field-level extensions.

## Patterns

- Prefer a concrete `app/inputs/*_input.rb` class for a new `as:` input.
- Use `SimpleForm::Inputs::*` overrides or prepends only for cross-cutting
  behavior on existing inputs.
- Call `register_stimulus(..., wrapper: true)` when behavior needs the whole
  `.form-group`; it marks the input as the controller `input` target.
- Put extra inline actions in `options[:input_controls]` via `append_input_control`.
- Put below-input HTML in `options[:custom_html]`; append instead of overwriting
  when decorating an existing input.

## Assets

- Standalone input assets live under `app/assets/javascripts/folio/input/*` and
  `app/assets/stylesheets/folio/input/*`, then are required/imported by the
  input manifests.
- Pack input assets stay in the pack asset tree and are required/imported by the
  pack manifest.
- Input-owned BEM blocks must be input blocks, not component blocks. For the AI
  pack, use `f-ai-input` and elements like `f-ai-input__controls`.
- Component sidecar classes and controllers stay with the component and own only
  component-rendered markup.

## Tests

- Test rendered form HTML with Capybara selectors, not private input methods.
- Cover both attachment and non-attachment gates for decorators.
- Keep controller names, data values, targets, `input_controls`, and
  `custom_html` selectors explicit in tests.

## Checks

- Ruby: `bundle exec rubocop --autocorrect-all <file_path>`.
- JS: `npx standard --fix <file_path>`.
- Slim: `bundle exec slim-lint <file_path>`.
