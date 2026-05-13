# frozen_string_literal: true

class Folio::Ai::Console::SiteSettingsComponent < Folio::Console::ApplicationComponent
  BEM_CLASS_NAME = "f-ai-c-site-settings"

  def initialize(form:)
    @form = form
    @site = form.object
  end

  def render?
    Folio::Ai.enabled? && integrations.present?
  end

  private
    def original_bem_class_name
      BEM_CLASS_NAME
    end

    def integrations
      Folio::Ai.registry.integrations_for_select
    end

    def providers
      Folio::Ai.provider_models.keys.map(&:to_s)
    end

    def provider_options
      provider_collection
    end

    def model_options(provider:, selected:, blank_label:)
      options = [[blank_label, ""]]
      return options unless Folio::Ai.known_provider?(provider)

      options += model_catalog_result(provider, selected).models.map do |option|
        [option.select_label, option.id]
      end

      options
    end

    def boolean_input(*path, label:, checked:)
      @form.input(input_attribute(*path),
                  as: :boolean,
                  label:,
                  required: false,
                  input_html: input_html(*path, checked:))
    end

    def provider_input(*path, label:, selected:, include_blank: false)
      select_input(*path,
                   label:,
                   collection: provider_options,
                   selected:,
                   include_blank:)
    end

    def model_input(*path, label:, provider:, selected:, blank_label:)
      select_input(*path,
                   label:,
                   collection: model_options(provider:, selected:, blank_label:),
                   selected: selected.to_s,
                   include_blank: false)
    end

    def text_area_input(*path, label:, value:, rows: 2)
      @form.input(input_attribute(*path),
                  as: :text,
                  label:,
                  required: false,
                  autosize: true,
                  input_html: input_html(*path, value:, rows:))
    end

    def select_input(*path, label:, collection:, selected:, include_blank:)
      @form.input(input_attribute(*path),
                  as: :select,
                  collection:,
                  include_blank:,
                  selected: selected.to_s,
                  label:,
                  required: false,
                  input_html: input_html(*path, class: "form-select"))
    end

    def input_attribute(*path)
      :"ai_settings_#{path.join('_')}"
    end

    def input_html(*path, **options)
      {
        name: field_name(*path),
        id: field_id(*path),
      }.merge(options)
    end

    def provider_collection
      providers.map { |provider| [provider_label(provider), provider] }
    end

    def provider_label(provider)
      t(".providers.#{provider}", default: provider.to_s.humanize)
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

    def field_label(integration, field)
      field.label(record_class: integration.record_class)
    end

    def default_provider
      (site_setting("default_provider").presence ||
        Folio::Ai.default_provider).to_s
    end

    def default_model
      site_setting("default_model")
    end

    def default_effective_model
      default_model.presence || provider_default_model(default_provider)
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

    def field_hint(field)
      return unless field.character_limit.present?

      t(".character_limit", count: field.character_limit)
    end
end
