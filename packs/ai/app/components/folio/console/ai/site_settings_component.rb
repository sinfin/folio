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

    def model_options(provider:, selected:, blank_label:)
      options = [[blank_label, ""]]
      return options_for_select(options, selected.to_s) unless Folio::Ai.known_provider?(provider)

      options += model_catalog_result(provider, selected).models.map do |option|
        [model_option_label(option), option.id]
      end

      options_for_select(options, selected.to_s)
    end

    def model_notice(provider:, selected:, effective_model:)
      return unless Folio::Ai.known_provider?(provider)

      model = selected.presence || effective_model
      return if model.blank?

      status = model_catalog(provider).status(model)

      if status.unavailable?
        t(".model_unavailable_notice",
          model:,
          provider: provider.to_s.humanize)
      elsif selected.present? && !status.verified?
        t(".model_catalog_unverified_notice",
          provider: provider.to_s.humanize)
      end
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

    def default_effective_model
      default_model.presence || provider_default_model(default_provider)
    end

    def default_model_notice
      model_notice(provider: default_provider,
                   selected: default_model,
                   effective_model: default_effective_model)
    end

    def integration_provider(integration)
      integration_setting(integration, "default_provider")
    end

    def integration_model(integration)
      integration_setting(integration, "default_model")
    end

    def integration_effective_provider(integration)
      integration_provider(integration).presence || default_provider
    end

    def integration_effective_model(integration)
      return integration_model(integration) if integration_model(integration).present?
      return provider_default_model(integration_provider(integration)) if integration_provider(integration).present?

      default_effective_model
    end

    def integration_model_notice(integration)
      model_notice(provider: integration_effective_provider(integration),
                   selected: integration_model(integration),
                   effective_model: integration_effective_model(integration))
    end

    def integration_blank_model_label(integration)
      if integration_provider(integration).present?
        provider_default_model_label(integration_provider(integration))
      else
        inherited_model_label(default_effective_model)
      end
    end

    def field_provider(integration, field)
      field_setting(integration, field, "provider")
    end

    def field_model(integration, field)
      field_setting(integration, field, "model")
    end

    def field_effective_provider(integration, field)
      field_provider(integration, field).presence || integration_effective_provider(integration)
    end

    def field_effective_model(integration, field)
      return field_model(integration, field) if field_model(integration, field).present?
      return provider_default_model(field_provider(integration, field)) if field_provider(integration, field).present?

      integration_effective_model(integration)
    end

    def field_model_notice(integration, field)
      model_notice(provider: field_effective_provider(integration, field),
                   selected: field_model(integration, field),
                   effective_model: field_effective_model(integration, field))
    end

    def field_blank_model_label(integration, field)
      if field_provider(integration, field).present?
        provider_default_model_label(field_provider(integration, field))
      else
        inherited_model_label(integration_effective_model(integration))
      end
    end

    def provider_default_model(provider)
      return unless Folio::Ai.known_provider?(provider)

      Folio::Ai.default_model(provider)
    end

    def provider_default_model_label(provider)
      default_model = provider_default_model(provider)

      if default_model.present?
        t(".provider_default_model", model: default_model)
      else
        t(".inherit_model")
      end
    end

    def inherited_model_label(model)
      if model.present?
        t(".inherited_model", model:)
      else
        t(".inherit_model")
      end
    end

    def model_catalog(provider)
      @model_catalogs ||= {}
      @model_catalogs[provider.to_s] ||= Folio::Ai::ModelCatalog.new(provider:)
    end

    def model_catalog_result(provider, selected)
      @model_catalog_results ||= {}
      @model_catalog_results[[provider.to_s, selected.to_s]] ||= model_catalog(provider).result(selected:)
    end

    def model_option_label(option)
      return option.select_label if option.available?

      t(".unavailable_model_option", model: option.select_label)
    end

    def field_hint(field)
      return unless field.character_limit.present?

      t(".character_limit", count: field.character_limit)
    end
end
