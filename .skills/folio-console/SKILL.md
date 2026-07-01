---
name: folio-console
description: >-
  Folio Console controllers, views, catalogue DSL, nested/through resources,
  route helpers, CRUD forms, position controls, and admin resource tests. Use
  when adding, fixing, or reviewing Folio::Console controllers or
  app/views/folio/console templates.
---

# Folio Console

## Controller Pattern

Use `folio_console_controller_for` for CRUD controllers. For nested resources,
prefer the built-in `through:` option so Folio scopes records and sets the parent
resource:

```ruby
class Folio::Console::App::Project::ItemsController < Folio::Console::BaseController
  folio_console_controller_for "App::Project::Item",
                               through: "App::Project",
                               as: :item
end
```

Folio derives the through route param from the parent model name, usually the
demodulized element such as `project_id`. Check `Parent.model_name.element` and
`rails routes` when the parent is namespaced or the route uses a custom param.

## Scaffold Generator

For new Console CRUD resources, start with the scaffold generator instead of
creating controller, view, and test files by hand:

```bash
rails generate folio:console:scaffold app/project/item --through App::Project
```

Use `--class-name` when the generated path and model constant differ. After
generation, inspect the generated routes, controller, views, and tests. Keep the
generated CRUD structure where it fits, then apply the nested catalogue and
rendered-output verification guidance below.

## Catalogue Blocks

The block passed to `catalogue(...)` is evaluated inside
`Folio::Console::CatalogueCell`, not in the original controller/view instance.
Controller instance variables can be unavailable or nil there even when
`through:` loaded them correctly.

Pass needed parent/through records explicitly to the catalogue and read them
from the cell model:

```slim
= catalogue(@items, project: @project)
  ruby:
    attribute(:to_label) do
      link_to(record.to_label, edit_console_app_project_item_path(model[:project], record))
    end

    published_toggle url: console_app_project_item_path(model[:project], record)

    position_controls url: set_positions_console_app_project_items_path(model[:project])

    actions edit: edit_console_app_project_item_path(model[:project], record),
            destroy: console_app_project_item_path(model[:project], record)
```

Do not rely on `@project` or `@parent` inside the catalogue DSL. Use
`model[:project]` or another explicitly passed key for nested route helpers,
`position_controls`, `published_toggle`, and `actions`.

## Verification

For nested sortable indexes, add a rendered-output regression test that proves
the concrete nested JSON URL is present:

```ruby
get console_app_project_items_path(project)

assert_response :success
assert_includes response.body, set_positions_console_app_project_items_path(project)
```

Prefer assertions against rendered links, forms, and URLs over controller
instance variables; Folio Console behavior often crosses controller, view, cell,
and route-helper boundaries.
