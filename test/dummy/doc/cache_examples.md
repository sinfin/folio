# Cache Examples for Folio Dummy App

Quick examples for testing cache functionality in the Folio dummy application.

## Quick Start

### Test Cache Headers

```bash
# Cache headers are enabled by default in dummy app
rails server

# Visit a page and check headers
curl -I http://dummy.localhost:3000

# Check that MiniProfiler is auto-disabled
# (no profiler widget should appear on page)

# To disable cache headers for testing:
FOLIO_CACHE_HEADERS_ENABLED=false rails server
```

### Test Fragment Caching

```bash
# Enable Rails fragment caching
rails dev:cache

# Start server (MiniProfiler auto-disabled)
rails server

# Check logs for cache activity
tail -f log/development.log | grep -i cache
```

### Force MiniProfiler During Cache Testing

```bash
# Enable both cache and profiler (may interfere)
MINI_PROFILER_FORCE_ENABLED=true FOLIO_CACHE_HEADERS_ENABLED=true rails server
```

## Environment Variable Examples

```bash
# Custom cache TTL (2 minutes)
FOLIO_CACHE_HEADERS_TTL=120 rails server

# Disable ETag headers
FOLIO_CACHE_HEADERS_ETAG=false rails server

# Emergency: disable all caching
FOLIO_CACHE_TTL_MULTIPLIER=0 rails server

# Custom stale-while-revalidate
FOLIO_CACHE_HEADERS_SWR=30 rails server
```

## Test URLs

- `/` - Home page (should cache)
- `/non-existent-page` - 404 error page (Cache-Control: no-store)
- `/console` - Admin area (Cache-Control: private, no-store)
- `/test?view=dummy/ui/buttons` - Test controller (should cache if published)

## Expected Headers

### Published Content (Cache Enabled)
```
Cache-Control: max-age=60, must-revalidate, stale-while-revalidate=15, stale-if-error=300
ETag: "abc123"
Last-Modified: Wed, 15 Nov 2023 10:30:00 GMT
Vary: Accept-Encoding, X-Auth-State
X-Auth-State: anonymous
```

### Unpublished/Error Content
```
Cache-Control: no-store
```

### Admin/Console Areas
```
Cache-Control: private, no-store
```

### Signed-in Users
```
Cache-Control: private, max-age=60
X-Auth-State: authenticated
```
