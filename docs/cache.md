# Cache Management in Folio

This document describes Folio's cache management system, including HTTP cache headers, fragment caching, and development tools integration.

## Overview

Folio provides a caching system with:
- **HTTP Cache Headers** - Smart browser and CDN caching (opt-in via config)
- **Fragment Caching** - View-level caching for performance  
- **Development Integration** - MiniProfiler management
- **Flexible Configuration** - ENV-based overrides for development

**Important**: Cache headers are **disabled by default** in Folio Engine. You must explicitly enable them in your application.

## HTTP Cache Headers

### Automatic Header Management

Folio after enabling automatically sets appropriate `Cache-Control` headers based on content type and publishing status:

```ruby
# Published content - cacheable
Cache-Control: max-age=60, must-revalidate, stale-while-revalidate=15, stale-if-error=300

# Unpublished content - not cacheable
Cache-Control: no-store

# 404 error pages - same TTL as regular pages (attack prevention)
Cache-Control: max-age=60, must-revalidate

# Server errors (500+) - shorter TTL
Cache-Control: max-age=15, must-revalidate

# Admin/console paths - never cached
Cache-Control: private, no-store

# Signed-in users - private cache
Cache-Control: private, max-age=60
```

### Configuration

Cache headers are configured in `config/initializers/cache_headers.rb` with ENV variable support:

```ruby
# Core settings
config.folio_cache_headers_enabled = true             # MASTER SWITCH - enables entire system
config.folio_cache_headers_default_ttl = 60           # Default TTL in seconds

# Header inclusion  
config.folio_cache_headers_include_etag = true        # Include ETag headers
config.folio_cache_headers_include_last_modified = true # Include Last-Modified headers  
config.folio_cache_headers_include_cache_tags = false # Include cache tags

# Advanced settings
config.folio_cache_headers_stale_while_revalidate = 15  # Stale-while-revalidate seconds
config.folio_cache_headers_stale_if_error = 300        # Stale-if-error seconds
```

All settings can be overridden via ENV variables (see Development Environment Controls below).

### Enabling Cache Headers in Your Application

Cache headers are **disabled by default** in Folio Engine. To enable them in your application:

#### Option 1: Create Initializer (Recommended)

Generate the cache headers initializer:
```bash
rails generate folio:cache_headers
```

This creates `config/initializers/cache_headers.rb` with cache headers enabled.

#### Option 2: Manual Configuration

Add to your `config/initializers/cache_headers.rb`:
```ruby
# Enable cache headers system
Rails.application.config.folio_cache_headers_enabled = true

# Configure other settings as needed
Rails.application.config.folio_cache_headers_default_ttl = 60
```

#### Option 3: Environment Variable

For testing or temporary enabling:
```bash
FOLIO_CACHE_HEADERS_ENABLED=true rails server
```

### Controller Usage

In your controllers, use `set_cache_control_headers`:

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
    set_cache_control_headers(record: @article)
  end
end
```

## Fragment Caching

### Folio Cache Patterns

Folio provides specific patterns for action and view caching:

#### Action Caching
```ruby
# In controllers - cache entire action logic
folio_run_unless_cached(["blog/articles#show", params[:id]] + cache_key_base) do
  @article = Article.find(params[:id])
  set_meta_variables(@article)
end
```

#### View Caching with Base Key
```slim
/ In views - cache with computed base key
- cache @cache_key
  .content
    = render @article
```

**Base Cache Key**: Controllers include `Folio::CacheMethods` and implement `cache_key_base` returning an array with user state, site context, and other cache-busting factors:

```ruby
def cache_key_base
  [request.host, user_signed_in? ? "logged_in" : "logged_out", I18n.locale]
end
```

### Development Fragment Caching

Enable fragment caching in development:

```bash
# Enable caching (creates tmp/caching-dev.txt)
rails dev:cache

# Disable caching (removes tmp/caching-dev.txt)  
rails dev:cache
```

Skip caching for debugging:
```
http://localhost:3000/articles/123?skip_global_cache=1
```

## Component Session Requirements

When cache optimization is active, components that need session state (forms, interactive elements) can declare their requirements to automatically disable session skipping when needed.

### Form Components

```ruby
class MyFormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(...)
    super
    # Automatically disables session optimization for this page
    require_session_for_component!("contact_form_csrf")
  end
end
```

### Atom Components

Atoms with forms work automatically on any page:

```ruby
class Economia::Atom::Forms::Leads::FormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
    # Ensures session is available even on cached pages
    require_session_for_component!("lead_atom_form")
  end
end
```

### How It Works

1. **Component declares session need** during rendering
2. **Controller tracks requirements** via `ComponentSessionRequirements`
3. **Cache optimization respects requirements** - disables session skip when needed
4. **Result**: Forms work correctly on cached pages

See **[Component Session Requirements Documentation](component-session-requirements.md)** for detailed implementation guide.

## Development Tools Integration

### Smart MiniProfiler Management

Folio automatically manages MiniProfiler to prevent interference with cache testing:

- **Cache ENABLED** → MiniProfiler **AUTO-DISABLED**
- **Cache DISABLED** → MiniProfiler **AUTO-ENABLED**

This prevents MiniProfiler from overriding cache headers during development testing.

### Manual Overrides

Force MiniProfiler behavior via environment variables:

```bash
# Force enable MiniProfiler (may interfere with cache testing)
MINI_PROFILER_FORCE_ENABLED=true rails server

# Force disable MiniProfiler
MINI_PROFILER_ENABLED=false rails server
```

## Development Environment Controls

### Cache Headers Control

Control cache headers in development via ENV variables:

```bash
# Enable cache headers in development
FOLIO_CACHE_HEADERS_ENABLED=true rails server

# Disable cache headers (default in development)
FOLIO_CACHE_HEADERS_ENABLED=false rails server

# Custom TTL
FOLIO_CACHE_HEADERS_TTL=120 rails server

# Disable ETag headers
FOLIO_CACHE_HEADERS_ETAG=false rails server

# Custom stale-while-revalidate
FOLIO_CACHE_HEADERS_SWR=30 rails server
```

### Emergency Cache Control

Control cache behavior via emergency ENV variables:

```bash
# Disable all caching immediately (sets Cache-Control: no-store)
FOLIO_CACHE_TTL_MULTIPLIER=0 rails server

# Reduce cache TTL by half
FOLIO_CACHE_TTL_MULTIPLIER=0.5 rails server

# Double cache TTL
FOLIO_CACHE_TTL_MULTIPLIER=2 rails server
```

## Development Banners

When starting the development server, Folio displays helpful banners:

### Cache Enabled
```
✅ FOLIO DEVELOPMENT CACHE: ENABLED
Store: Memory Store
Fragment cache logging: ON
Public file headers: 172800s TTL
MiniProfiler: Auto-disabled (prevents interference)
To disable: rails dev:cache
Documentation: docs/cache.md
```

### Cache Disabled
```
❌ FOLIO DEVELOPMENT CACHE: DISABLED
Store: :null_store (no caching)
Fragment caching is OFF
Cache headers are OFF
MiniProfiler: Auto-enabled
To enable: rails dev:cache
This will create tmp/caching-dev.txt
Documentation: docs/cache.md
```

## Cloudflare Cache Optimization

### Problem: Set-Cookie Headers Cause BYPASS

Cloudflare automatically sets `cf-cache-status: BYPASS` for responses with `Set-Cookie` headers, preventing CDN caching. Rails applications commonly send:

- **Session cookies** (`_session_id`) - Rails default behavior
- **Log cookies** (`s_for_log`, `u_for_log`) - Folio tracking cookies

### Solution: Session Skip for Public Responses

Enable cache-friendly mode that skips session cookies for anonymous users:

```bash
# Enable in production for Cloudflare optimization
FOLIO_CACHE_SKIP_SESSION=true rails server
```

**What it does:**
- Skips Rails session cookies for public cache responses
- Skips Folio log cookies for anonymous users  
- Allows Cloudflare to cache instead of BYPASS
- Maintains cookies for signed-in users (private cache)
- **Note:** Business-specific cookies (like UTM tracking) maintain their own logic

**Safety:**
- ✅ Safe for anonymous content that doesn't need session state
- ✅ CSRF protection still works via meta tags
- ✅ User authentication unaffected
- ✅ Flash messages work normally for signed-in users

### Configuration

```ruby
# config/initializers/cache_headers.rb
Rails.application.config.folio_cache_skip_session_for_public = true

# or via ENV
ENV["FOLIO_CACHE_SKIP_SESSION"] = "true"
```

### Testing Cloudflare Cache

```bash
# Without session skip (will get BYPASS)
curl -I https://yoursite.com/ | grep -E "set-cookie|cf-cache"

# With session skip enabled  
FOLIO_CACHE_SKIP_SESSION=true rails server
curl -I https://yoursite.com/ | grep -E "set-cookie|cf-cache"
# Should see no set-cookie headers for anonymous requests
```

## Form and Interactive Components

### Built-in Session Management

Folio automatically handles session requirements for form controllers:

```ruby
# Folio::LeadsController - automatically requires session for form submissions
class Folio::LeadsController < Folio::ApplicationController
  include Folio::RequiresSession
  requires_session_for :form_functionality, only: [:create]
end

# Folio::Api::NewsletterSubscriptionsController - session for newsletter signups
class Folio::Api::NewsletterSubscriptionsController < Folio::Api::BaseController
  include Folio::RequiresSession
  requires_session_for :newsletter_subscription, only: [:create]
end
```

### Component Integration

Form components automatically declare session requirements:

```ruby
# Lead forms require session for CSRF and flash messages
class Folio::Leads::FormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(lead: nil)
    @lead = lead || Folio::Lead.new
    require_session_for_component!("lead_form_csrf_and_flash")
  end
end

# Newsletter forms require session for CSRF and Turnstile
class Folio::NewsletterSubscriptions::FormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(newsletter_subscription: nil, view_options: {})
    @newsletter_subscription = newsletter_subscription || Folio::NewsletterSubscription.new
    require_session_for_component!("newsletter_subscription_csrf_and_turnstile")
  end
end
```

### Expected Cache Performance

With component session requirements:
```
Pages with forms:       ~65% cache hit ratio (session required)
Pages without forms:    ~75% cache hit ratio (full optimization)
Overall improvement:    ~70% vs current ~30%
```

## Common Development Workflows

### Testing Cache Headers

1. Enable cache headers:
   ```bash
   FOLIO_CACHE_HEADERS_ENABLED=true rails server
   ```

2. Check headers in browser DevTools or curl:
   ```bash
   curl -I http://localhost:3000/some-page
   ```

3. Notice MiniProfiler is automatically disabled

### Testing Fragment Caching

1. Enable Rails caching:
   ```bash
   rails dev:cache
   ```

2. Check logs for cache hits/misses:
   ```
   Cache read: views/articles/1-20231201123456/article
   Cache write: views/articles/1-20231201123456/article
   ```

3. Notice MiniProfiler is automatically disabled

### Debug Cache Issues

1. Enable detailed logging:
   ```bash
   FOLIO_CACHE_HEADERS_ENABLED=true rails server
   ```

2. Check logs for cache decisions:
   ```
   [Cache Headers] ArticlesController -> public (get_request_signed_out_2xx_with_record)
   Headers: Cache-Control: max-age=60, must-revalidate, stale-while-revalidate=15
   ```

### Force MiniProfiler During Cache Testing

```bash
# If you need MiniProfiler while testing cache
MINI_PROFILER_FORCE_ENABLED=true FOLIO_CACHE_HEADERS_ENABLED=true rails server
```

⚠️ **Warning**: This may interfere with cache header testing as MiniProfiler injects its own headers.

## Best Practices

### Development

1. **Test with cache enabled** - Periodically enable caching to catch issues early
2. **Check logs** - Cache decision logging helps debug issues
3. **Use ENV overrides** - Quickly test different cache configurations

### Production

1. **Enable cache headers** - They're enabled by default in production
2. **Monitor cache hit rates** - Use CDN analytics to track effectiveness
3. **Test emergency overrides** - Ensure `FOLIO_CACHE_TTL_MULTIPLIER=0` works
4. **Validate ETag/Last-Modified** - Check that conditional requests work

### Content Management

1. **Use `set_cache_control_headers(record: @model)`** - Automatic unpublished detection
2. **Test preview mode** - Ensure unpublished content isn't cached
3. **Consider cache invalidation** - Plan for content update workflows
4. **Monitor stale content** - Use `stale-while-revalidate` appropriately

## Troubleshooting

### Headers Not Appearing

1. Check if cache headers are enabled:
   ```ruby
   Rails.application.config.folio_cache_headers_enabled
   ```

2. Verify the path should be cached:
   ```ruby
   # Console/admin paths are never cached
   request.path.starts_with?("/console") # Should be false
   ```

3. Check for existing headers:
   ```ruby
   # Headers set earlier take precedence
   response.headers["Cache-Control"] # Should be nil before setting
   ```

### MiniProfiler Interference

1. Check if auto-disabled:
   ```
   [MiniProfiler] 🔄 Auto-disabled (caching active)
   ```

2. Force enable if needed:
   ```bash
   FORCE_MINI_PROFILER=true rails server
   ```

3. Verify in browser that cache headers are correct (MiniProfiler may add its own)

### Fragment Cache Not Working

1. Ensure caching is enabled:
   ```bash
   rails dev:cache
   ```

2. Check for cache store:
   ```ruby
   Rails.cache.class # Should not be NullStore
   ```

3. Verify cache key generation:
   ```erb
   <% cache @article do %>
     <!-- This generates a key like: views/articles/1-20231201123456/article -->
   <% end %>
   ```

## Related Documentation

- [Folio HTTP Cache Headers](../app/controllers/concerns/folio/http_cache/headers.rb) - Implementation details
- [Rails Caching Guide](https://guides.rubyonrails.org/caching_with_rails.html) - Rails caching basics
- [MiniProfiler](https://github.com/MiniProfiler/rack-mini-profiler) - Profiler documentation
