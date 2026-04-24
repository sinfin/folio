# frozen_string_literal: true

class Folio::Ai::RequestGuard
  def initialize(site:,
                 user:,
                 integration_key:,
                 field_key:,
                 prompt:)
    @site = site
    @user = user
    @integration_key = integration_key
    @field_key = field_key
    @prompt = prompt.to_s
  end

  def check!
    check_prompt_length!
    check_rate_limit!
  end

  private
    attr_reader :site,
                :user,
                :integration_key,
                :field_key,
                :prompt

    def check_prompt_length!
      return if max_prompt_chars.blank?
      return if prompt.length <= max_prompt_chars

      raise Folio::Ai::CostLimitExceededError, "AI prompt is too long"
    end

    def check_rate_limit!
      Folio::Ai::RateLimiter.new(site:,
                                 user:,
                                 integration_key:,
                                 field_key:).check!
    end

    def max_prompt_chars
      Rails.application.config.folio_ai_max_prompt_chars
    end
end
