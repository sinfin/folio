# frozen_string_literal: true

class Folio::Ai::Availability
  Result = Struct.new(:available, :reason, :field, keyword_init: true) do
    def available?
      available
    end
  end

  def initialize(site:,
                 integration_key:,
                 field_key:,
                 host_eligible: true,
                 global_enabled: Folio::Ai.enabled?)
    @site = site
    @integration_key = integration_key
    @field_key = field_key
    @host_eligible = host_eligible
    @global_enabled = global_enabled
  end

  def call
    return unavailable(:global_disabled) unless global_enabled
    return unavailable(:site_disabled) unless site&.ai_enabled?
    return unavailable(:field_not_registered) unless field
    return unavailable(:field_disabled, field:) unless site.ai_field_enabled_for?(integration_key:, field_key:)
    return unavailable(:prompt_missing, field:) if default_prompt.blank?
    return unavailable(:host_ineligible, field:) unless host_eligible

    Result.new(available: true, reason: nil, field:)
  end

  private
    attr_reader :site,
                :integration_key,
                :field_key,
                :host_eligible,
                :global_enabled

    def field
      @field ||= Folio::Ai.registry.field(integration_key, field_key)
    end

    def default_prompt
      site.ai_prompt_for(integration_key:, field_key:)
    end

    def unavailable(reason, field: nil)
      Result.new(available: false, reason:, field:)
    end
end
