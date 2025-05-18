# Concerns

Folio extracts shared functionality into Ruby modules located under `app/models/concerns/folio/` and `app/controllers/concerns/folio/`. These modules can be mixed into your own classes to add behaviour or helper scopes.

## Model Concerns

| Module | Purpose |
|--------|---------|
| `HasAtoms` | Adds association and helpers for CMS block atoms |
| `Thumbnails` | Generates and manages image thumbnails |
| `Publishable` | Common scopes and callbacks for published/unpublished state |
| `Positionable` / `PositionableDescending` | Ordering helpers for sortable lists |
| `BelongsToSite` | Adds `site` relation used for multi‑site projects |
| `Filterable` | Provides `filter_by_params` and dynamic `by_*` scopes |
| `Taggable` | Adds tagging via `acts-as-taggable-on` |
| `HasSecretHash` | Generates a unique token for secure URLs |

See the source under [`app/models/concerns/folio`](../app/models/concerns/folio) for the full list.

## Controller Concerns

Controller modules live in `app/controllers/concerns/folio`. Important ones include:

- `ApplicationControllerBase` – sets `Folio::Current` context
- `PagesControllerBase` – helpers for page rendering
- `ApiControllerBase` – JSON API helpers
- `Console::DefaultActions` – common CRUD actions for admin controllers

Include these modules in custom controllers as needed.

---

[← Back to Architecture](architecture.md)
