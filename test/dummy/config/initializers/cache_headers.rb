# frozen_string_literal: true

# Enable cache headers in dummy app for testing
Rails.application.config.folio_cache_headers_enabled = true
Rails.application.config.folio_cache_headers_default_ttl = 60
Rails.application.config.folio_cache_headers_include_etag = true
Rails.application.config.folio_cache_headers_include_last_modified = true
Rails.application.config.folio_cache_headers_include_cache_tags = false

# Emergency TTL multiplier is controlled via ENV variable FOLIO_CACHE_TTL_MULTIPLIER
# Example: export FOLIO_CACHE_TTL_MULTIPLIER=0.5 to halve all TTL values
