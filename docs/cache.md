# Folio::Cache (Cache Pack)

Versioned fragment cache invalidation system. When models change, associated cache versions update automatically, invalidating related fragment caches.

## Setup

Enable the cache pack:

```ruby
# config/initializers/folio.rb
Folio.enabled_packs = %w[cache]
```

Run the migration:

```bash
rails db:migrate
```

## How It Works

1. `Folio::Cache::Version` stores key-timestamp pairs per site
2. Models declare which cache keys they invalidate via `folio_cache_version_keys`
3. Views use `folio_cache` helper with version keys
4. On model commit, version timestamps update, invalidating caches

## Model Setup

Override `folio_cache_version_keys` to declare which cache keys a model invalidates:

```ruby
class Article < Folio::ApplicationRecord
  private
    def folio_cache_version_keys
      keys = %w[articles]
      keys << "published" if published?
      keys
    end
end
```

The `after_commit` callback automatically calls `Folio::Cache::Invalidator` with the model's `site_id` and declared keys.

## View Helper

Use `folio_cache` in views and components:

```slim
/ Basic usage
- folio_cache @article, keys: %w[articles] do
  = render @article

/ With options
- folio_cache @page, keys: %w[published navigation], if: @page.published?, expires_in: 2.hours do
  = @page.content
```

**Parameters:**

- `name` - Cache key (record, string, array)
- `keys:` - Array of `Folio::Cache::Version` keys (default: `[]`)
- `expires_in:` - Cache TTL (default: `Folio::Cache::DEFAULT_EXPIRES_IN` = 1 hour)
- `if:`, `unless:` - Conditional caching

Works in both views and ViewComponents.

## Manual Invalidation

```ruby
Folio::Cache::Invalidator.invalidate!(
  site_id: current_site.id,
  keys: %w[articles navigation]
)
```

Missing version records are created automatically.
