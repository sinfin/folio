# frozen_string_literal: true

class Folio::Ai::ProviderConfig
  Result = Struct.new(:provider,
                      :model,
                      :requested_model,
                      :warnings,
                      keyword_init: true)

  def initialize(site:, integration_key:, field_key:)
    @site = site
    @integration_key = integration_key
    @field_key = field_key
  end

  def call
    provider, model = resolve_provider_model
    raise Folio::Ai::UnknownProviderError, "Unknown AI provider: #{provider}" unless Folio::Ai.known_provider?(provider)
    raise ArgumentError, "AI model is blank for provider: #{provider}" if model.blank?

    Result.new(provider: provider.to_sym,
               model:,
               requested_model: model,
               warnings: [])
  end

  private
    attr_reader :site,
                :integration_key,
                :field_key

    def resolve_provider_model
      site_provider = normalize_provider(ai_settings["default_provider"].presence ||
                                         Rails.application.config.folio_ai_default_provider)
      site_model = ai_settings["default_model"].presence || default_model_for(site_provider)

      integration_provider_override = integration_settings["default_provider"].presence
      integration_provider = normalize_provider(integration_provider_override || site_provider)
      integration_model = scoped_model(integration_settings["default_model"],
                                       provider_override: integration_provider_override,
                                       provider: integration_provider,
                                       inherited_model: site_model)

      field_provider_override = field_settings["provider"].presence
      field_provider = normalize_provider(field_provider_override || integration_provider)
      field_model = scoped_model(field_settings["model"],
                                 provider_override: field_provider_override,
                                 provider: field_provider,
                                 inherited_model: integration_model)

      [field_provider, field_model]
    end

    def scoped_model(model_override, provider_override:, provider:, inherited_model:)
      return model_override if model_override.present?
      return default_model_for(provider) if provider_override.present?

      inherited_model
    end

    def default_model_for(provider)
      return unless Folio::Ai.known_provider?(provider)

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
