# frozen_string_literal: true

# MiniProfiler Smart Configuration for Folio Development
# Automatically manages MiniProfiler based on cache settings to prevent interference
# with cache header testing and fragment cache debugging.
#
# This initializer runs after cache_headers.rb to read the already-configured settings.
#
# ENV Controls:
# - MINI_PROFILER_FORCE_ENABLED=true  - Force enable (may interfere with cache testing)
# - MINI_PROFILER_ENABLED=false       - Force disable

if Rails.env.development?
  # Check if development caching is enabled (rails dev:cache)
  caching_enabled = Rails.root.join("tmp/caching-dev.txt").exist?

  # Check if Folio cache headers are enabled (configured in cache_headers.rb initializer)
  cache_headers_enabled = Rails.application.config.respond_to?(:folio_cache_headers_enabled) &&
                         Rails.application.config.folio_cache_headers_enabled

  if caching_enabled || cache_headers_enabled
    # Auto-disable MiniProfiler when caching is active to prevent interference
    Rack::MiniProfiler.config.enabled = false

    Rails.logger.info "[MiniProfiler] ❌ Auto-disabled (caching active)"
    Rails.logger.info "[MiniProfiler] This prevents cache header interference in development"

    if caching_enabled
      Rails.logger.info "[MiniProfiler] Reason: Fragment caching enabled (tmp/caching-dev.txt exists)"
    end

    if cache_headers_enabled
      Rails.logger.info "[MiniProfiler] Reason: Folio cache headers enabled"
    end
  else
    # Enable MiniProfiler with optimal settings when caching is disabled
    Rack::MiniProfiler.config.enabled = true
    Rack::MiniProfiler.config.position = "bottom-right"
    Rack::MiniProfiler.config.show_total_sql_count = true
    Rack::MiniProfiler.config.show_controls = true

    Rails.logger.info "[MiniProfiler] ✅ Enabled (caching disabled)"
    Rails.logger.info "[MiniProfiler] Position: bottom-right, SQL count: ON"
  end

  # ENV overrides for developer control
  if ENV["MINI_PROFILER_FORCE_ENABLED"] == "true"
    Rack::MiniProfiler.config.enabled = true
    Rails.logger.warn "[MiniProfiler] ⚠️ Force-enabled via MINI_PROFILER_FORCE_ENABLED=true"
    Rails.logger.warn "[MiniProfiler] This may interfere with cache testing!"
  elsif ENV["MINI_PROFILER_ENABLED"] == "false"
    Rack::MiniProfiler.config.enabled = false
    Rails.logger.info "[MiniProfiler] ❌ Force-disabled via MINI_PROFILER_ENABLED=false"
  end

  # Skip certain paths that should never be profiled
  Rack::MiniProfiler.config.skip_paths ||= []
  Rack::MiniProfiler.config.skip_paths += [
    "/rails/mailers/",
    "/console/",
    "/assets/"
  ]
end
