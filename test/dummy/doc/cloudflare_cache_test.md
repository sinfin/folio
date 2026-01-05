# Cloudflare Cache Testing Guide

This document shows how to test Cloudflare cache optimization with session skip functionality.

## Problem

Cloudflare sets `cf-cache-status: BYPASS` for responses with `Set-Cookie` headers, preventing CDN caching.

**Common cookies that cause BYPASS:**
- Rails session cookies (`_session_id`)
- Folio log cookies (`s_for_log`, `u_for_log`) 
- Business-specific cookies (UTM tracking, etc.) - handled by their own logic

## Testing Setup

### 1. Default Behavior (Session Cookies Sent)

```bash
# Start server with default configuration
FOLIO_CACHE_HEADERS_ENABLED=true rails server

# Test anonymous request
curl -I http://dummy.localhost:3000/ | grep -E "set-cookie|cache-control"

# Expected result:
set-cookie: s_for_log=...; path=/; SameSite=Lax
set-cookie: _session_id=...; path=/; expires=...; HttpOnly; SameSite=Lax
cache-control: public, max-age=60, must-revalidate, stale-while-revalidate=15, stale-if-error=300

# Cloudflare would see Set-Cookie and return BYPASS
```

### 2. Optimized Behavior (Session Skip Enabled)

```bash
# Start server with session skip optimization
FOLIO_CACHE_HEADERS_ENABLED=true FOLIO_CACHE_SKIP_SESSION=true rails server

# Test anonymous request
curl -I http://dummy.localhost:3000/ | grep -E "set-cookie|cache-control"

# Expected result:
cache-control: public, max-age=60, must-revalidate, stale-while-revalidate=15, stale-if-error=300
# No set-cookie headers!

# Cloudflare can now cache this response instead of BYPASS
```

## Configuration Options

### Development Testing

```bash
# Enable cache headers with session skip
FOLIO_CACHE_HEADERS_ENABLED=true FOLIO_CACHE_SKIP_SESSION=true rails server

# Test different pages
curl -I http://dummy.localhost:3000/              # Should cache (no cookies)
curl -I http://dummy.localhost:3000/console       # Should not cache (private)
curl -I http://dummy.localhost:3000/non-existent  # Should cache 404 (no cookies)
```

### Production Configuration

```ruby
# config/initializers/cache_headers.rb

# Enable cache headers
Rails.application.config.folio_cache_headers_enabled = true

# Enable Cloudflare optimization (skip session cookies for public responses)
Rails.application.config.folio_cache_skip_session_for_public = true
```

## Safety Considerations

### What's Safe ✅

- **Anonymous browsing** - No session state needed
- **Static content** - Public pages, articles, etc.
- **SEO crawlers** - Better cache hit rates
- **CSRF protection** - Still works via meta tags

### What's Maintained ✅

- **Signed-in users** - Still get session cookies (private cache)
- **Admin areas** - Always private/no-store
- **Form submissions** - CSRF tokens from meta tags
- **Authentication** - Login/logout still works

### What to Monitor 📊

- **Cloudflare cache status** - Should see more HIT, less BYPASS
- **Session-dependent features** - Test thoroughly in staging
- **Analytics tracking** - May need adjustment for anonymous users

## Troubleshooting

### Still Getting BYPASS?

1. **Check other cookies** - Third-party cookies may still trigger BYPASS
2. **Verify configuration** - Ensure `FOLIO_CACHE_SKIP_SESSION=true`
3. **Test logged-out** - Session skip only works for anonymous users
4. **Check Cloudflare rules** - Custom page rules may override behavior

### Missing User Tracking?

If you rely on session-based analytics:

```ruby
# Consider client-side tracking instead
# Or use server-side tracking that doesn't require cookies
```

## Monitoring Results

### Before Optimization
```
cf-cache-status: BYPASS (due to Set-Cookie)
Cache hit ratio: ~30-40%
```

### After Optimization  
```
cf-cache-status: HIT (anonymous users)
cf-cache-status: MISS → HIT (subsequent requests)
Cache hit ratio: ~70-80%
```

This optimization can significantly improve your Cloudflare cache hit ratio and reduce origin server load.
