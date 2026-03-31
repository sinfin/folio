# Folio::RecordCache (Record cache pack)

Identity Cache integration for hot reads on Folio models. Complements [fragment cache versioning](cache.md): `Folio::Cache` tracks version keys for HTML fragments; this pack caches Active Record rows so repeated `find` / slug lookups can avoid SQL when the cache is warm.

Invalidation is handled by Identity Cache’s own `after_commit` hooks. It does **not** call `Folio::Cache::Invalidator`.

## Setup

Enable the pack alongside others:

```ruby
# config/initializers/folio.rb
Folio.enabled_packs = %w[cache record_cache]
```

The pack sets `IdentityCache.cache_backend = Rails.cache` at boot. Use a **shared** cache store in production (for example Redis or Memcached) so all app processes see the same Identity Cache entries; per-process `MemoryStore` is not suitable for multi-server deployments.

Identity Cache recommends a cache backend with CAS (compare-and-swap) for consistency. If your store does not support CAS, Identity Cache may log a warning; choose a supported backend for production.

No extra migration is required for Identity Cache itself.

## How it works

1. **`Folio::FindOrFetch`** is included in `Folio::ApplicationRecord`. Without the pack, `find_or_fetch` uses normal Active Record scopes (`by_site`, `published_or_preview_token`, `where`, then `friendly.find` or `find`).
2. With the record_cache pack loaded, Folio models include pack concerns that override `find_or_fetch` to load via Identity Cache when possible, then apply `published`, `site`, and `with:` checks in Ruby.
3. **`Folio::Site.find_or_fetch_by_slug` / `find_or_fetch_by_domain`** are used by `Folio::Current.get_site`. With the pack, those resolve through Identity Cache (`fetch_by_slug` / `fetch_by_domain`).

**Note:** `Folio::Current.cache_aware_get_site` may still wrap the site in `Rails.cache.fetch`. That is an additional layer on top of Identity Cache; both can be warm with zero SQL.

## `find_or_fetch` API

```ruby
Model.find_or_fetch(slug_or_id,
  published: nil,
  site: nil,
  preview_token: nil,
  with: nil)
```

- **`published: true`** — applies `published_or_preview_token(preview_token)` when the model defines that scope (same idea as [`Folio::Publishable`](../app/models/concerns/folio/publishable.rb)). Omit or use `false`/`nil` to skip that filter.
- **`site:`** — scopes with `by_site(site)` when present, then (with the pack) verifies `record.site_id` matches.
- **`preview_token:`** — passed into `published_or_preview_token` for the DB path; with the pack, a matching token can bypass the published check (see `Folio::Publishable`).
- **`with:`** — hash of attribute names to expected values (string equality after `to_s`).
- **Unsupported options** — Passing `site:` when the model has no `by_site` scope, or `published: true` when it has no `published_or_preview_token` scope, raises `ArgumentError` (with or without the record_cache pack).

### Examples (generic)

```ruby
# Published page for the current site (typical public show action)
Folio::Page.find_or_fetch(params[:id],
  published: true,
  site: Folio::Current.site,
  preview_token: params[Folio::Publishable::PREVIEW_PARAM_NAME],
  with: { locale: I18n.locale.to_s })

# By id
Folio::Site.find_or_fetch(site_id)
```

Host applications whose models inherit from `ApplicationRecord` instead of `Folio::ApplicationRecord` should `include Folio::FindOrFetch` on their base class (see the dummy app).

## Folio models in this pack

| Model | Behavior |
|-------|----------|
| `Folio::Site` | `cache_index` on `slug` and `domain` (unique). |
| `Folio::Page` | When `config.folio_using_traco` is **false**: `cache_index` on `slug` and `site_id` (unique). With **Traco** (localized slug columns), the pack does not register this concern; use the default DB `find_or_fetch` only. |
| `Folio::File` | Primary key `fetch` only. |
| `Folio::Menu` | Primary key `fetch` only (no composite index on type/site/locale; the schema does not enforce uniqueness on that tuple). |

## Host-defined models

The railtie only prepends concerns onto Folio’s own models. To use Identity Cache on your own models, add `include IdentityCache`, declare `cache_index` fields that match real uniqueness in the database, and mirror the guard logic in `Folio::RecordCache::BaseConcern` (or extract a small module in your app).

## Relationship to `Folio::Cache`

- **Record cache pack** — row-level Identity Cache; good for “load this `Page` / `Site` without hitting the DB.”
- **[Cache pack](cache.md)** — versioned fragment keys and `folio_cache` helper for HTML.

Use both for warm public pages: resolve the record with `find_or_fetch`, then wrap fragments with `folio_cache` and the appropriate version keys.

## Error messages

In **production**, failed `find_or_fetch` checks raise `ActiveRecord::RecordNotFound` with a generic message. In **development** and **test**, messages may include more detail to aid debugging.
