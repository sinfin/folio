---
name: folio-embed-data
description: >-
  Folio embed-data conventions for folio_embed_data, as: :embed, canonical
  embed JSON, embed validation, rendering, migrations, and console forms. Use
  when replacing legacy embed URL, HTML, or source fields, or when changing
  model-backed Folio embeds.
---

# Folio embed data

Persist canonical `folio_embed_data` JSON; do not substitute a custom string
field or application-specific embed parsing.

## Contract

Use one normalized active shape:

```json
{ "active": true, "html": "..." }
```

```json
{ "active": true, "type": "youtube", "url": "..." }
```

- Use `Folio::Embed.normalize_value` in model writers. It normalizes inactive,
  blank, and malformed input to `nil`.
- Do not treat normalization as source validation: reject unsupported active
  types or URLs with Folio validation. `EmbedInput` checks
  `invalid_reason_for` before it normalizes invalid browser input to inactive.
- Take supported URL types from `data/embed/source/types.json`; extend Folio
  itself rather than inventing application-specific parsing.

## Models and persistence

- Use a nullable JSONB column when an embed is optional or is one branch of a
  content-kind selector. Do not use `default: {}` or `null: false` where the
  normalizer represents blank data as `nil`.
- For an unconditional embed, include `Folio::Embed::Validation`. For mutually
  exclusive image/embed variants, gate or override `validate_folio_embed_data`
  so the image variant can save without embed JSON.
- Configure HTML sanitization deliberately with
  `folio_embed_data: :unsafe_html` in `folio_html_sanitization_config`.

## Console forms and parameters

- Use `f.input :folio_embed_data, as: :embed`; do not build a custom source
  textarea or embed controller.
- `EmbedInput` owns the preview and serializes JSON into its hidden field.
  Browser and controller tests must submit `folio_embed_data.to_json` and
  permit the scalar field for this form contract.
- If an API accepts nested embed hashes, explicitly permit
  `Folio::Embed.hash_strong_params_keys`; do not assume that shape works for
  the console hidden input.

## Rendering, migrations, and tests

- Render embeds with `Folio::Embed::BoxComponent`.
- Migrate legacy data only when its semantics and deployed data justify it.
  Keep migrations reversible and never guess whether a legacy value is HTML or
  a URL.
- Test normalization, conditional validation, sanitization, serialized JSON
  submission, and the image/embed switch independently.

## Folio implementation

- [Embed normalization and validation](../../app/lib/folio/embed.rb)
- [Embed SimpleForm input](../../app/inputs/embed_input.rb)
- [Embed validation concern](../../app/models/concerns/folio/embed/validation.rb)
- [Embed rendering component](../../app/components/folio/embed/box_component.rb)
