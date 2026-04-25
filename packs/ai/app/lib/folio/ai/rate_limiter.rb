# frozen_string_literal: true

class Folio::Ai::RateLimiter
  def initialize(site:,
                 user:,
                 integration_key:,
                 field_key:)
    @site = site
    @user = user
    @integration_key = integration_key
    @field_key = field_key
  end

  def check!
    return unless enabled?

    count = Rails.cache.increment(cache_key, 1, expires_in: expires_in)
    count ||= write_initial_count

    raise Folio::Ai::RateLimitExceededError, "AI request rate limit exceeded" if count > limit
  end

  private
    attr_reader :site,
                :user,
                :integration_key,
                :field_key

    def enabled?
      rate_limit.present? && limit.positive? && period.positive?
    end

    def write_initial_count
      Rails.cache.write(cache_key, 1, expires_in:)
      1
    end

    def cache_key
      [
        "folio_ai_rate_limit",
        site&.id || "site",
        user&.id || "user",
        integration_key.to_s,
        field_key.to_s,
        Time.current.to_i / period,
      ].join(":")
    end

    def expires_in
      period + 5.seconds
    end

    def limit
      rate_limit_value(:limit).to_i
    end

    def period
      rate_limit_value(:period).to_i
    end

    def rate_limit_value(key)
      return 0 unless rate_limit.respond_to?(:[])

      rate_limit[key] || rate_limit[key.to_s] || 0
    end

    def rate_limit
      Rails.application.config.folio_ai_rate_limit
    end
end
