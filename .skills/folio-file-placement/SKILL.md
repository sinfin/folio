---
name: folio-file-placement
description: >-
  Folio custom file placement conventions: Folio::FilePlacement subclasses,
  has_one_placement / has_many_placements relations, placement_key and
  placements_key naming, Console file pickers, placement strong params, I18n,
  STI type renames, tests, seeds, catalogue covers, and eager loading. Use when
  adding, renaming, fixing, or reviewing custom file placements or
  file-picker-backed attachments.
---

# Folio File Placements

## Naming Alignment

Name custom placement classes with enough feature scope. Prefer a specific name
such as `ProjectListingItemRectangularImage`; avoid vague names such as
`RectangularImage` when the placement belongs to a specific model, component, or
listing context.

Keep the class, file path, relation, placement key, form key, strong-param key,
and I18n key aligned:

```ruby
# app/models/economia/file_placement/project_listing_item_rectangular_image.rb
class Economia::FilePlacement::ProjectListingItemRectangularImage < Folio::FilePlacement::Image
end

has_one_placement :project_listing_item_rectangular_image,
                  placement_key: :project_listing_item_rectangular_image_placement,
                  placement: "Economia::FilePlacement::ProjectListingItemRectangularImage"
```

For the example above, use:

- `project_listing_item_rectangular_image` for the logical file relation
- `project_listing_item_rectangular_image_placement` for the placement relation
- `project_listing_item_rectangular_image_placement_attributes` for nested params
- `project_listing_item_rectangular_image_placement` for Console picker labels
- `Economia::FilePlacement::ProjectListingItemRectangularImage` for STI `type`

For `has_many_placements`, apply the same rule to the plural placement relation
and `*_placements_attributes` key.

## Console And Params

Update every Console surface to use the same placement name:

- file picker `placement_key` / helper argument
- catalogue cover/image source
- form strong params through `file_placements_strong_params`
- app or host `additional_file_placements_strong_params_keys`, unless the key is
  intentionally controller-local
- controller tests and rendered form/component tests

Do not add a custom placement to a form without allowing its
`*_placement_attributes` key, or the picker may render while saves silently drop
the file placement params.

## I18n

Add both levels of translation:

- the placement model key under `activerecord.models.*`, so STI placement names
  are readable in model-facing UI
- the top-level `attributes.*_placement` key, so Console picker labels resolve
  for the placement relation rendered by the form

The top-level key should match the placement relation, not the logical file
getter.

## Rename Checklist

When adding or renaming a placement, update all related references in one pass:

- placement class and file path
- `has_one_placement` / `has_many_placements` declaration
- `placement_key` / `placements_key`
- Console form file picker keys
- catalogue cover usage
- component calls and eager-load includes
- seed task constants
- controller, component, and model tests
- `additional_file_placements_strong_params_keys`
- `activerecord.models.*` and top-level `attributes.*_placement` I18n keys

When renaming STI placement classes, account for existing database `type` values
or confirm the old placements were deleted or backfilled. A code rename alone
does not migrate existing rows.

## Verification

After a placement change, run focused model, controller, and component tests that
touch the picker and rendered placement. Also run an exact stale-name scan for
the old class/relation names and `git diff --check`.

Prefer rendered-output assertions for Console forms and catalogues, and assert
the concrete `*_placement_attributes` input names when params wiring is the
risk.

## Related Skills

- Use [`.skills/folio-rails-models/SKILL.md`](../folio-rails-models/SKILL.md)
  for validation and required-marker behavior around placement fields.
- Use [`.skills/folio-console/SKILL.md`](../folio-console/SKILL.md) for Console
  controller, catalogue, and rendered-output test conventions.
- Use [`.skills/folio-testing/SKILL.md`](../folio-testing/SKILL.md) for focused
  behavior-facing test coverage.
