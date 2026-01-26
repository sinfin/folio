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

**Performance:** Cache versions are loaded once per request into `Folio::Current.cache_versions_hash` on first `folio_cache` usage, then filtered from memory for subsequent calls.

## Model Setup

Override `folio_cache_version_keys` to declare which cache keys a model invalidates:

```ruby
class Article < Folio::ApplicationRecord
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

## Scheduled Expiration

For time-sensitive content (e.g., scheduled article publishing), configure automatic cache expiration:

### Configuration

```ruby
# config/initializers/folio_cache.rb
Folio::Cache.configure do |config|
  config.expires_at_for_key = ->(key:, site:) do
    case key
    when "published_articles"
      Dummy::Blog::Article.folio_cache_expires_at(site:)
    end
  end
end
```

For temporary configuration in tests, use the block form (automatically reverts after block):

```ruby
Folio::Cache.configure do
  Folio::Cache.expires_at_for_key = ->(key:, site:) { 1.day.from_now }
  # ... test code ...
end
# expires_at_for_key is automatically reset to previous value
```

### Publishable Models

Models using `Folio::Publishable::WithDate` or `Folio::Publishable::Within` automatically get the `folio_cache_expires_at(site:)` class method, which returns the next datetime when any record's published status will change.

```ruby
# Returns next scheduled publish/unpublish time
Article.folio_cache_expires_at(site: current_site)
```

### How It Works

1. When `expires_at` is configured, it's stored on `Folio::Cache::Version`
2. Cache keys include an expired flag (0/1) based on current time vs `expires_at`
3. When expiration is detected, a background job invalidates the version
4. The lambda is called again to calculate the next `expires_at`
