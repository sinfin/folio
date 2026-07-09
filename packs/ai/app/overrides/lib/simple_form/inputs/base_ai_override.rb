# frozen_string_literal: true

# Decorates eligible SimpleForm text inputs with AI suggestion controls.
module Folio::Ai::SimpleFormInputExtension
  CONTROLLER_NAME = "f-ai-input"

  def add_text_suggestions(input_type:)
    super if defined?(super)

    config = ai_text_suggestions_config
    return unless config

    availability = ai_text_suggestions_availability(config)
    return unless availability

    register_ai_text_suggestions(config,
                                 show_button: availability.fetch(:show_button))
  end

  private
    def ai_text_suggestions_config
      return unless options.key?(:ai)
      return if options[:ai] == false || options[:ai].nil?

      ai_options = normalized_ai_options
      record = ai_options.fetch(:record, @builder.object)
      field_key = ai_options.fetch(:key, ai_options.fetch(:field_key, attribute_name)).to_s

      {
        record:,
        record_key: record_key_for(record),
        field_key:,
        suggestion_count: ai_options.fetch(:suggestion_count, Folio::Ai::DEFAULT_SUGGESTION_COUNT),
        grouped: ai_options.fetch(:grouped, false),
      }
    end

    def normalized_ai_options
      return {} if options[:ai] == true
      raise ArgumentError, "SimpleForm ai: must be true, false, or a hash" unless options[:ai].respond_to?(:to_h)

      options[:ai].to_h.symbolize_keys
    end

    def record_key_for(record)
      record.class.table_name if record&.class&.respond_to?(:table_name)
    end

    def ai_text_suggestions_availability(config)
      return unless ai_text_suggestions_base_available?(config)

      show_button = ai_prompt_enabled?(config)
      return unless show_button || grouped_prompt_enabled_for_field?(config)

      { show_button: }
    end

    def ai_text_suggestions_base_available?(config)
      Folio::Ai.config.enabled? &&
        persisted_ai_record?(config[:record]) &&
        ai_site_enabled?(config[:record]) &&
        registered_ai_field?(config) &&
        !ai_input_disabled? &&
        ai_provider_available?(config[:record])
    end

    def registered_ai_field?(config)
      Folio::Ai.registry.field(config[:record_key], config[:field_key]).present?
    end

    def ai_site_enabled?(record)
      site = ai_site(record)

      !site.respond_to?(:ai_enabled?) || site.ai_enabled?
    end

    def ai_provider_available?(record)
      site = ai_site(record)
      provider_key = site&.respond_to?(:ai_provider) ? site.ai_provider : Folio::Ai.config.default_provider
      provider_model = site&.respond_to?(:ai_model) ? site.ai_model : Folio::Ai.config.default_model(provider_key)

      Folio::Ai.provider_for(key: provider_key,
                             model: provider_model)
      true
    rescue Folio::Ai::ProviderError, ArgumentError, KeyError
      false
    end

    def persisted_ai_record?(record)
      record.respond_to?(:persisted?) && record.persisted?
    end

    def ai_input_disabled?
      options[:disabled] ||
        options[:readonly] ||
        input_html_options[:disabled] ||
        input_html_options[:readonly]
    end

    def ai_prompt_enabled?(config)
      site = ai_site(config[:record])
      return false unless site.respond_to?(:ai_prompt_enabled_for?)

      site.ai_prompt_enabled_for?(record_key: config[:record_key],
                                  key: config[:field_key],
                                  grouped: false)
    end

    def grouped_prompt_enabled_for_field?(config)
      site = ai_site(config[:record])
      record = Folio::Ai.registry.record(config[:record_key])
      return false unless site.respond_to?(:ai_prompt_enabled_for?) && record

      record.fetch(:groups).values.any? do |group|
        group.fetch(:fields).include?(config[:field_key]) &&
          site.ai_prompt_enabled_for?(record_key: config[:record_key],
                                      key: group.fetch(:key),
                                      grouped: true)
      end
    end

    def ai_site(record)
      record.respond_to?(:site) ? record.site : Folio::Current.site
    end

    def register_ai_text_suggestions(config, show_button:)
      ensure_ai_input_id
      mark_ai_wrapper
      append_ai_custom_html(config,
                            show_button:)

      register_stimulus(CONTROLLER_NAME,
                        wrapper: true,
                        action: ai_input_actions,
                        values: ai_input_values(config))

      append_ai_input_action
    end

    def ensure_ai_input_id
      input_html_options[:id] ||= Folio::Ai::ComponentIds.default_input_id(object_name: @builder.object_name,
                                                                           field_key: attribute_name)
    end

    def mark_ai_wrapper
      options[:wrapper_html] ||= {}
      options[:wrapper_html][:class] = Array(options[:wrapper_html][:class])
      options[:wrapper_html][:class] << "form-group--with-ai-text-suggestions"
      options[:wrapper_html][:class].uniq!
    end

    def ai_input_actions
      {
        "f-ai-c-input-controls:toggle": "toggle",
        "f-ai-c-input-controls:undo": "undoSuggestion",
        "f-ai-c-text-suggestions:close": "close",
        "f-ai-c-text-suggestions:regenerate": "regenerate",
        "f-ai-c-text-suggestions:accept": "acceptSuggestion",
        "f-ai-c-text-suggestions-group:loading": "showGroupLoading",
        "f-ai-c-text-suggestions-group:result": "showGroupResult",
        "f-ai-input/close": "close",
        "f-ai-input/message": "onMessage",
      }
    end

    def ai_input_values(config)
      {
        url: ai_text_suggestions_url,
        klass: config[:record].class.name,
        record_id: config[:record].id,
        key: config[:field_key],
        grouped: config[:grouped],
        suggestion_count: config[:suggestion_count],
        component_id: ai_text_suggestions_component_id,
      }
    end

    def append_ai_input_action
      action = "input->#{CONTROLLER_NAME}#onInput"
      input_html_options["data-action"] = [input_html_options["data-action"], action].compact.join(" ")
    end

    def append_ai_custom_html(config, show_button:)
      options[:custom_html] = @builder.template.safe_join([
        options[:custom_html],
        ai_text_suggestions_component(config,
                                      show_button:),
      ].compact)
    end

    def ai_text_suggestions_component(config, show_button:)
      @builder.template.render(Folio::Ai::Console::InputControlsComponent.new(component_id: ai_text_suggestions_component_id,
                                                                              label: ai_text_suggestions_label(config),
                                                                              show_button:))
    end

    def ai_text_suggestions_label(config)
      field = Folio::Ai.registry.field(config[:record_key], config[:field_key])
      I18n.t("folio.ai.input.button",
             field: ai_field_label(config, field))
    end

    def ai_field_label(config, field)
      field[:label].presence ||
        config[:record].class.human_attribute_name(config[:field_key]) ||
        config[:field_key].humanize
    end

    def ai_text_suggestions_url
      Folio::Engine.routes.url_helpers.console_api_ai_text_suggestions_path
    end

    def ai_text_suggestions_component_id
      Folio::Ai::ComponentIds.text_suggestions_component_id(input_id: input_html_options[:id])
    end
end

unless SimpleForm::Inputs::Base < Folio::Ai::SimpleFormInputExtension
  SimpleForm::Inputs::Base.prepend(Folio::Ai::SimpleFormInputExtension)
end
