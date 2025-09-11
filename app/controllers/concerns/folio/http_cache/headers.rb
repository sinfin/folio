# frozen_string_literal: true

module Folio
  module HttpCache
    module Headers
      extend ActiveSupport::Concern

      included do
      end

      private
        def set_cache_control_headers(record: nil)
          # No auto-detection - controllers must explicitly provide record if needed

          if record && record.respond_to?(:published?) && !record.published?
            no_store
            log_cache_decision("no_store", "unpublished_record", record: record)
            return
          end

          unless Rails.application.config.respond_to?(:folio_cache_headers_enabled) && Rails.application.config.folio_cache_headers_enabled
            log_cache_decision("skip", "cache_headers_disabled")
            return
          end

          # Check emergency cache TTL multiplier from ENV
          multiplier = ENV["FOLIO_CACHE_TTL_MULTIPLIER"]&.to_f
          if multiplier == 0.0
            no_store
            log_cache_decision("no_store", "emergency_cache_disabled", multiplier: multiplier)
            return
          end

          # Respect headers set earlier in the request lifecycle
          if response.headers["Cache-Control"].present?
            log_cache_decision("skip", "cache_control_already_set", headers: response.headers["Cache-Control"])
            return
          end

          unless should_set_cache_headers?
            skip_reason = if request.path.starts_with?("/console")
              "console_path"
            elsif request.path.starts_with?("/users")
              "users_path"
            else
              "other_excluded_path"
            end
            log_cache_decision("skip", skip_reason, path: request.path)
            return
          end

          # Preview mode should never be cached - contains unpublished content
          if params[Folio::Publishable::PREVIEW_PARAM_NAME].present?
            no_store
            log_cache_decision("no_store", "preview_mode", preview_token: params[Folio::Publishable::PREVIEW_PARAM_NAME])
            return
          end

          if should_cache_response?
            ttl = calculate_cache_ttl(record)

            if should_use_private_cache?
              # Private cache - bypasses Cloudflare but allows browser caching
              set_private_cache_headers_with_ttl(ttl)
              reason = determine_cache_reason("private_signed_in")
              log_cache_decision_with_headers("private", reason, ttl: ttl, user: Folio::Current.user&.id)
            else
              # Public cache - Cloudflare will cache this
              if record && (Rails.application.config.folio_cache_headers_include_etag || Rails.application.config.folio_cache_headers_include_last_modified)
                set_freshness_headers(record, ttl)
                reason = determine_cache_reason("with_record")
                log_cache_decision_with_headers("public_with_freshness", reason, ttl: ttl, record: record)
              else
                set_public_cache_headers(ttl)
                reason = determine_cache_reason("no_record")
                log_cache_decision_with_headers("public", reason, ttl: ttl)
              end
            end
          else
            set_private_cache_headers
            reason = if !request.get?
              "non_get_request"
            elsif !(response.status.to_i >= 200 && response.status.to_i < 300)
              "non_2xx_status"
            else
              "should_not_cache"
            end
            log_cache_decision_with_headers("no_cache", reason,
                              user: Folio::Current.user&.id,
                              method: request.method,
                              status: response.status)
          end
        end

        def should_set_cache_headers?
          !request.path.starts_with?("/console") && !request.path.starts_with?("/users")
        end

        def should_cache_response?
          return false unless request.get? && response.status.to_i >= 200 && response.status.to_i < 300

          # Special paths that should be cached regardless of user login status
          return true if is_static_content_path?

          # Cache public content for everyone, but use private cache for signed-in users
          # This allows Cloudflare to cache for anonymous users while serving fresh content to signed-in users
          true
        end

        def should_use_private_cache?
          # Use private cache (bypasses Cloudflare) for signed-in users
          Folio::Current.user.present?
        end

        def is_static_content_path?
          request.path.match?(/\/(robots\.txt|sitemap\.xml)$/)
        end

        def calculate_cache_ttl(record)
          base_ttl = (Rails.application.config.respond_to?(:folio_cache_headers_default_ttl) && Rails.application.config.folio_cache_headers_default_ttl) || 60

          # Apply emergency multiplier from ENV if set
          multiplier = ENV["FOLIO_CACHE_TTL_MULTIPLIER"]&.to_f
          if multiplier && multiplier != 1.0 && multiplier > 0.0
            base_ttl = (base_ttl * multiplier).round
          end

          # Use shorter TTL for error pages (404 etc.) - they might be temporary
          if response.status.to_i >= 400
            [base_ttl / 4, 15].max  # quarter of default TTL, minimum 15s
          else
            base_ttl
          end
        end

        def set_public_cache_headers(ttl)
          response.headers["Cache-Control"] = "public, max-age=#{ttl}, s-maxage=#{ttl}"

          # Add Vary headers for compression and authentication state
          existing_vary = response.headers["Vary"].to_s
          vary_values = existing_vary.split(",").map(&:strip)

          # Always include Accept-Encoding for compression
          unless vary_values.include?("Accept-Encoding")
            vary_values << "Accept-Encoding"
          end

          # Add custom header to separate cache by authentication state
          # We'll add X-Auth-State header and vary on it instead of all cookies
          set_auth_state_header
          unless vary_values.include?("X-Auth-State")
            vary_values << "X-Auth-State"
          end

          response.headers["Vary"] = vary_values.reject(&:blank?).join(", ")
        end

        def set_private_cache_headers
          response.headers["Cache-Control"] = "no-cache"
        end

        def set_private_cache_headers_with_ttl(ttl)
          # Private cache with TTL - bypasses Cloudflare but allows browser caching
          response.headers["Cache-Control"] = "private, max-age=#{ttl}"

          # Add Vary headers for compression and authentication state
          existing_vary = response.headers["Vary"].to_s
          vary_values = existing_vary.split(",").map(&:strip)

          # Always include Accept-Encoding for compression
          unless vary_values.include?("Accept-Encoding")
            vary_values << "Accept-Encoding"
          end

          # Add custom header to maintain cache separation even for private responses
          set_auth_state_header
          unless vary_values.include?("X-Auth-State")
            vary_values << "X-Auth-State"
          end

          response.headers["Vary"] = vary_values.reject(&:blank?).join(", ")
        end

        def set_freshness_headers(record, ttl)
          return unless record

          timestamp = calculate_last_modified_timestamp(record)

          if Rails.application.config.folio_cache_headers_include_last_modified && timestamp
            fresh_when(record, last_modified: timestamp, public: true)
            # Override Cache-Control to include our TTL
            response.headers["Cache-Control"] = "max-age=#{ttl}, public, s-maxage=#{ttl}"
          elsif Rails.application.config.folio_cache_headers_include_etag
            fresh_when(record, public: true)
            # Override Cache-Control to include our TTL
            response.headers["Cache-Control"] = "max-age=#{ttl}, public, s-maxage=#{ttl}"
          end

          # Ensure Vary header is set with both compression and auth state
          existing_vary = response.headers["Vary"].to_s
          vary_values = existing_vary.split(",").map(&:strip)

          unless vary_values.include?("Accept-Encoding")
            vary_values << "Accept-Encoding"
          end

          # Add custom header to separate cache by authentication state
          set_auth_state_header
          unless vary_values.include?("X-Auth-State")
            vary_values << "X-Auth-State"
          end

          response.headers["Vary"] = vary_values.reject(&:blank?).join(", ")
        end

        # Default Last-Modified calculation. Apps can override in their controllers.
        def calculate_last_modified_timestamp(record)
          record.updated_at if record.respond_to?(:updated_at)
        end

        # Declared for clarity, apps can override.
        def cache_timestamp_columns
          [:updated_at]
        end

        # Logging cache header decisions for debugging (non-production only)
        def log_cache_decision(action, rule_name, **details)
          return if Rails.env.production?

          controller_name = self.class.name.demodulize
          record_info = if details[:record]
            "#{details[:record].class.name}##{details[:record].id}"
          else
            "no_record"
          end

          log_details = details.except(:record).map { |k, v| "#{k}=#{v}" }.join(", ")
          log_message = "[Cache Headers] #{controller_name} -> #{action} (#{rule_name})"
          log_message += " | #{record_info}" if details[:record]
          log_message += " | #{log_details}" if log_details.present?

          Rails.logger.info(log_message)
        end

        def determine_cache_reason(record_type)
          if response.status.to_i >= 400
            "error_#{response.status}_#{record_type}"
          elsif is_static_content_path?
            "static_content_#{record_type}"
          elsif record_type == "private_signed_in"
            "get_request_signed_in_2xx_private"
          else
            "get_request_signed_out_2xx_#{record_type}"
          end
        end

        # Set authentication state header for precise cache separation
        def set_auth_state_header
          # Simple binary state: authenticated or anonymous
          auth_state = Folio::Current.user ? "authenticated" : "anonymous"
          response.headers["X-Auth-State"] = auth_state
        end

        # Enhanced logging with actual response headers
        def log_cache_decision_with_headers(action, rule_name, **details)
          return if Rails.env.production?

          controller_name = self.class.name.demodulize
          record_info = if details[:record]
            record = details[:record]
            last_modified = calculate_last_modified_timestamp(record)
            "#{record.class.name}##{record.id} (updated: #{last_modified&.strftime('%Y-%m-%d %H:%M:%S')})"
          else
            "no_record"
          end

          # Collect actual response headers
          headers_info = []
          headers_info << "Cache-Control: #{response.headers['Cache-Control']}" if response.headers["Cache-Control"]
          headers_info << "ETag: #{response.headers['ETag']}" if response.headers["ETag"]
          headers_info << "Last-Modified: #{response.headers['Last-Modified']}" if response.headers["Last-Modified"]
          headers_info << "Vary: #{response.headers['Vary']}" if response.headers["Vary"]
          headers_info << "X-Accel-Expires: #{response.headers['X-Accel-Expires']}" if response.headers["X-Accel-Expires"]

          # Configuration info
          config_info = []
          config_info << "etag=#{Rails.application.config.folio_cache_headers_include_etag}"
          config_info << "last_modified=#{Rails.application.config.folio_cache_headers_include_last_modified}"
          config_info << "cache_tags=#{Rails.application.config.folio_cache_headers_include_cache_tags}"

          log_details = details.except(:record).map { |k, v| "#{k}=#{v}" }.join(", ")

          log_message = "[Cache Headers] #{controller_name} -> #{action} (#{rule_name})"
          log_message += " | #{record_info}" if details[:record]
          log_message += " | #{log_details}" if log_details.present?
          log_message += "\n  Headers: #{headers_info.join(', ')}"
          log_message += "\n  Config: #{config_info.join(', ')}"
          log_message += "\n  Path: #{request.path}"

          Rails.logger.info(log_message)
        end
    end
  end
end
