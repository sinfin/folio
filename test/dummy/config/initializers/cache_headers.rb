# frozen_string_literal: true

# Folio Cache Headers Configuration
# Centralized configuration with ENV variable support for flexible development

# Core cache headers settings
# MASTER SWITCH - enables entire cache headers system
# Default: enabled in dummy app for testing, opt-in for real applications
Rails.application.config.folio_cache_headers_enabled =
  ENV.fetch("FOLIO_CACHE_HEADERS_ENABLED") { "true" }.to_s.in?(["true", "1"])

Rails.application.config.folio_cache_headers_default_ttl =
  ENV.fetch("FOLIO_CACHE_HEADERS_TTL") { "60" }.to_i

# Header inclusion settings
Rails.application.config.folio_cache_headers_include_etag =
  ENV.fetch("FOLIO_CACHE_HEADERS_ETAG") { "true" }.to_s.in?(["true", "1"])

Rails.application.config.folio_cache_headers_include_last_modified =
  ENV.fetch("FOLIO_CACHE_HEADERS_LAST_MODIFIED") { "true" }.to_s.in?(["true", "1"])

Rails.application.config.folio_cache_headers_include_cache_tags =
  ENV.fetch("FOLIO_CACHE_HEADERS_TAGS") { "false" }.to_s.in?(["true", "1"])

# Advanced cache control settings
Rails.application.config.folio_cache_headers_stale_while_revalidate =
  ENV.fetch("FOLIO_CACHE_HEADERS_SWR") { "15" }.to_i

Rails.application.config.folio_cache_headers_stale_if_error =
  ENV.fetch("FOLIO_CACHE_HEADERS_SIE") { "300" }.to_i

# Emergency TTL multiplier is controlled via ENV variable FOLIO_CACHE_TTL_MULTIPLIER
# Example: export FOLIO_CACHE_TTL_MULTIPLIER=0.5 to halve all TTL values
# Example: export FOLIO_CACHE_TTL_MULTIPLIER=0 to disable all caching immediately

# Cloudflare Cache Optimization
# Skip session cookies for public responses to prevent Cloudflare BYPASS
# Default: disabled (opt-in for production optimization)
Rails.application.config.folio_cache_skip_session_for_public =
  ENV.fetch("FOLIO_CACHE_SKIP_SESSION") { "false" }.to_s.in?(["true", "1"])
