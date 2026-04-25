# frozen_string_literal: true

class Folio::Console::Ai::SiteSettingsComponent < Folio::Console::ApplicationComponent
  def initialize(form:)
    @form = form
    @site = form.object
  end

  def render?
    Folio::Ai.enabled? && integrations.present?
  end

  private
    def integrations
      Folio::Ai.registry.integrations_for_select
    end

    def providers
      Folio::Ai.provider_models.keys.map(&:to_s)
    end

    def provider_options(selected)
      options_for_select(providers.map { |provider| [provider.humanize, provider] }, selected)
    end

    def field_name(*path)
      "#{@form.object_name}[ai_settings]#{path.map { |key| "[#{key}]" }.join}"
    end

    def field_id(*path)
      "#{@form.object_name}_ai_settings_#{path.join("_")}".parameterize(separator: "_")
    end

    def site_setting(key)
      @site.ai_settings_data[key.to_s]
    end

    def integration_setting(integration, key)
      @site.ai_settings_data.dig("integrations", integration.key, key.to_s)
    end

    def field_setting(integration, field, key)
      @site.ai_settings_data.dig("integrations",
                                 integration.key,
                                 "fields",
                                 field.key,
                                 key.to_s)
    end

    def site_enabled?
      @site.ai_enabled?
    end

    def field_enabled?(integration, field)
      @site.ai_field_enabled_for?(integration_key: integration.key,
                                  field_key: field.key)
    end

    def field_prompt(integration, field)
      @site.ai_prompt_for(integration_key: integration.key,
                          field_key: field.key)
    end

    def default_provider
      (site_setting("default_provider").presence ||
        Rails.application.config.folio_ai_default_provider).to_s
    end

    def default_model
      site_setting("default_model")
    end

    def integration_provider(integration)
      integration_setting(integration, "default_provider")
    end

    def integration_model(integration)
      integration_setting(integration, "default_model")
    end

    def field_provider(integration, field)
      field_setting(integration, field, "provider")
    end

    def field_model(integration, field)
      field_setting(integration, field, "model")
    end

    def field_hint(field)
      return unless field.character_limit.present?

      t(".character_limit", count: field.character_limit)
    end
end
