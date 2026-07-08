# frozen_string_literal: true

# Renders site-level AI provider/model settings and registered field prompts.
class Folio::Ai::Console::SiteSettingsComponent < Folio::Console::ApplicationComponent
  def initialize(form:)
    @form = form
    @site = form.object
  end

  def render?
    Folio::Ai.config.enabled?
  end

  private
    def provider_configuration_available?
      providers.present?
    end

    def records
      Folio::Ai.registry.records
    end

    def fields(record)
      record.fetch(:fields).values
    end

    def boolean_input(*path, label:, checked:)
      @form.input(input_attribute(*path),
                  as: :boolean,
                  label:,
                  required: false,
                  input_html: input_html(*path, checked:))
    end

    def provider_input(*path, label:, selected:)
      @form.input(input_attribute(*path),
                  as: :select,
                  collection: provider_options,
                  include_blank: false,
                  selected: selected.to_s,
                  label:,
                  required: false,
                  input_html: input_html(*path, class: "form-select"))
    end

    def model_input(*path, label:, provider:, selected:)
      @form.input(input_attribute(*path),
                  as: :select,
                  collection: model_options(provider:, selected:),
                  include_blank: false,
                  selected: selected.to_s,
                  label:,
                  required: false,
                  input_html: input_html(*path, class: "form-select"))
    end

    def text_area_input(*path, label:, value:)
      @form.input(input_attribute(*path),
                  as: :text,
                  label:,
                  required: false,
                  autosize: true,
                  input_html: input_html(*path, value:, rows: 2))
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

    def field_name(*path)
      "#{@form.object_name}[ai_settings]#{path.map { |key| "[#{key}]" }.join}"
    end

    def field_id(*path)
      "#{@form.object_name}_ai_settings_#{path.join('_')}".parameterize(separator: "_")
    end

    def provider_options
      providers.keys.map { |provider| [provider_label(provider), provider.to_s] }
    end

    def providers
      Folio::Ai.available_providers
    end

    def provider_label(provider)
      t(".providers.#{provider}", default: provider.to_s.humanize)
    end

    def enabled_label
      t(".enabled_label", default: "Enable AI suggestions for this site")
    end

    def provider_input_label
      t(".provider", default: "Provider")
    end

    def model_input_label
      t(".model", default: "Model")
    end

    def prompt_label
      t(".prompt_label", default: "Prompt")
    end

    def no_providers_text
      t(".no_providers", default: "Configure an AI provider before editing AI suggestion settings for this site.")
    end

    def site_enabled?
      @site.respond_to?(:ai_enabled?) && @site.ai_enabled?
    end

    def selected_provider
      provider = site_setting("provider").presence || @site.ai_provider
      return provider.to_s if providers.key?(provider.to_sym)

      providers.keys.first.to_s
    end

    def model_value
      site_setting("model")
    end

    def model_options(provider:, selected:)
      options = [[model_placeholder(provider), ""]]

      [*provider_models(provider), selected].compact_blank.uniq.each do |model|
        options << [model, model]
      end

      options
    end

    def model_placeholder(provider)
      model = provider_default_model(provider)
      return t(".model_placeholder_blank", default: "Provider default") if model.blank?

      t(".model_placeholder", model:, default: "Default: %{model}")
    end

    def field_prompt(record, field)
      @site.ai_prompt_for(record_key: record.fetch(:key),
                          field_key: field.fetch(:key))
    end

    def site_setting(key)
      @site.ai_settings_data[key.to_s]
    end

    def field_hint(field)
      return unless field[:character_limit].present?

      t(".character_limit",
        count: field[:character_limit],
        default: "Limit: %{count} characters")
    end

    def provider_default_model(provider)
      provider_class(provider)&.default_model
    end

    def provider_models(provider)
      provider_class(provider)&.models || []
    end

    def provider_class(provider)
      providers[provider.to_sym]
    end
end
