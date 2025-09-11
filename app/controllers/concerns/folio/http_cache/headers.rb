# frozen_string_literal: true

module Folio
  module HttpCache
    module Headers
      extend ActiveSupport::Concern

      included do
      end

      private
        def set_cache_control_headers(record: nil)
          if record && record.respond_to?(:published?) && !record.published?
            no_store
            return
          end

          return unless Rails.application.config.respond_to?(:folio_cache_headers_enabled) && Rails.application.config.folio_cache_headers_enabled

          # Respect headers set earlier in the request lifecycle
          return if response.headers["Cache-Control"].present?

          return unless should_set_cache_headers?

          if should_cache_response?
            ttl = calculate_cache_ttl(record)

            # Set freshness headers first (they may set Cache-Control)
            if record && (Rails.application.config.folio_cache_headers_include_etag || Rails.application.config.folio_cache_headers_include_last_modified)
              set_freshness_headers(record, ttl)
            else
              set_public_cache_headers(ttl)
            end
          else
            set_private_cache_headers
          end
        end

        def should_set_cache_headers?
          !request.path.starts_with?("/console")
        end

        def should_cache_response?
          request.get? && !Folio::Current.user && response.status.to_i >= 200 && response.status.to_i < 300
        end

        def calculate_cache_ttl(record)
          (Rails.application.config.respond_to?(:folio_cache_headers_default_ttl) && Rails.application.config.folio_cache_headers_default_ttl) || 60
        end

        def set_public_cache_headers(ttl)
          response.headers["Cache-Control"] = "public, max-age=#{ttl}, s-maxage=#{ttl}"

          existing_vary = response.headers["Vary"].to_s
          vary_values = existing_vary.split(",").map(&:strip)
          unless vary_values.include?("Accept-Encoding")
            vary_values << "Accept-Encoding"
            response.headers["Vary"] = vary_values.reject(&:blank?).join(", ")
          end
        end

        def set_private_cache_headers
          response.headers["Cache-Control"] = "no-cache"
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

          # Ensure Vary header is set
          existing_vary = response.headers["Vary"].to_s
          vary_values = existing_vary.split(",").map(&:strip)
          unless vary_values.include?("Accept-Encoding")
            vary_values << "Accept-Encoding"
            response.headers["Vary"] = vary_values.reject(&:blank?).join(", ")
          end
        end

        # Default Last-Modified calculation. Apps can override in their controllers.
        def calculate_last_modified_timestamp(record)
          record.updated_at if record.respond_to?(:updated_at)
        end

        # Declared for clarity, apps can override.
        def cache_timestamp_columns
          [:updated_at]
        end
    end
  end
end
