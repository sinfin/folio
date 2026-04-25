# frozen_string_literal: true

class Folio::Ai::ProviderConfig
  Result = Struct.new(:provider, :model, keyword_init: true)

  def initialize(site:, integration_key:, field_key:)
    @site = site
    @integration_key = integration_key
    @field_key = field_key
  end

  def call
    provider = resolve_provider
    raise Folio::Ai::UnknownProviderError, "Unknown AI provider: #{provider}" unless Folio::Ai.known_provider?(provider)

    model = resolve_model(provider)
    raise ArgumentError, "AI model is blank for provider: #{provider}" if model.blank?

    Result.new(provider: provider.to_sym, model:)
  end

  private
    attr_reader :site,
                :integration_key,
                :field_key

    def resolve_provider
      normalize_provider(field_settings["provider"].presence ||
                         integration_settings["default_provider"].presence ||
                         ai_settings["default_provider"].presence ||
                         Rails.application.config.folio_ai_default_provider)
    end

    def resolve_model(provider)
      field_settings["model"].presence ||
        integration_settings["default_model"].presence ||
        ai_settings["default_model"].presence ||
        Folio::Ai.default_model(provider)
    end

    def normalize_provider(provider)
      provider.to_s.strip
    end

    def ai_settings
      site.ai_settings_data
    end

    def integration_settings
      ai_settings.dig("integrations", integration_key.to_s) || {}
    end

    def field_settings
      site.ai_field_settings(integration_key:, field_key:)
    end
end
