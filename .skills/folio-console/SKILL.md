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

## Nested Route Names

When a nested Console resource model is namespaced under the parent model, make
the route helper prefix match the child model route key. Otherwise Folio and
Rails polymorphic helpers can infer impossible names such as
`console_project_project_item_path`, and generated helpers inside catalogue
actions, form actions, toggles, or redirects will fail.

For `App::Project::Item`, `model_name.route_key` is usually
`app_project_items`, so the nested route should override `as:`:

```ruby
resources :projects do
  resources :items,
            as: :app_project_items,
            controller: "project/items" do
    post :set_positions, on: :collection
  end
end
```

After adding or changing nested Console routes, run:

```bash
rails routes -g project_items
```

Verify the generated prefixes line up with the model route key and with the
polymorphic calls used by the views, for example:

```ruby
url_for([:console, record.project, record])
url_for([:set_positions, :console, record.project, App::Project::Item])
```

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
`through:` loaded them correctly. Prefer route helpers that can be generated
from `record` and its parent when the route `as:` is aligned correctly.

Pass needed parent/through records explicitly to the catalogue and read them
from the cell model:

```slim
= catalogue(@items, project: @project)
  ruby:
    edit_link :to_label

    published_toggle url: url_for([:console, record.project, record])

    position_controls url: url_for([:set_positions, :console, record.project, App::Project::Item])

    actions
```

Do not rely on `@project` or `@parent` inside the catalogue DSL. Either use
`record.project` or pass the parent explicitly to `catalogue` and read it as
`model[:project]`. For nested resources, first fix the route `as:` so standard
Folio/polymorphic helpers work; explicit helper paths in catalogue blocks should
be the fallback, not the first solution.

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
