---
name: folio-rails-models
description: >-
  Rails and ActiveModel model conventions for Folio: validations, form-facing
  attributes, console required-marker inference, attachment/file placement
  validation targets, and model behavior that affects admin forms. Use when
  adding or changing model validations, virtual attributes, attachment
  validations, or console-administered model fields.
---

# Rails models (Folio)

Use this skill when model validations or virtual attributes affect how records
behave in Folio console forms.

## Form-facing validations

- SimpleForm required asterisks are inferred from standard presence validators
  on the rendered form attribute for any console-administered model.
- Custom validation methods do not make SimpleForm infer a required field. If a
  marker is missing, first check whether there is an unconditional
  `validates :attribute, presence: true` on the same attribute the form renders.
- For helpers/components that render a label for a generated or related
  attribute, validate that rendered attribute or pass `required:` explicitly.
  Examples: `validates :link, presence: true` marks `f.input :link`;
  `validates :cover_placement, presence: true` marks a picker label rendered
  for `cover_placement`.

## File attachments

- Folio file picker labels are rendered for the file placement key, not the
  logical file getter. For `file_picker_for_cover`, the asterisk appears with
  `cover_placement`, not `cover`, because the picker label is
  `@f.label @placement_key`.
- Validate the logical file getter when the model behavior should require an
  actual file. Validate the placement attribute, or pass `required:`, when the
  console form label must show the required marker.

## Embed data

- Normalize `folio_embed_data` on assignment.
- Use conditional embed validation for mutually exclusive content variants.
- Keep optional embed persistence nullable to follow the normalizer's `nil`
  contract, and configure unsafe-HTML sanitization deliberately.
- Follow [`.skills/folio-embed-data/SKILL.md`](../folio-embed-data/SKILL.md)
  for the canonical embed contract and implementation details.

## Related skills

- Use [`.skills/folio-simple-form-inputs/SKILL.md`](../folio-simple-form-inputs/SKILL.md)
  when changing SimpleForm input classes, wrappers, or generated input HTML.
- Use [`.skills/folio-rails-code-structure/SKILL.md`](../folio-rails-code-structure/SKILL.md)
  when changing model method structure or extracting multi-step model logic.
