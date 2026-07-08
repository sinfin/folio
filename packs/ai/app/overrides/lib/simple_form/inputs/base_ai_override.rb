# frozen_string_literal: true

module Folio::Ai::SimpleFormInputExtension
  include Folio::StimulusHelper

  CONTROLLER_NAME = "f-ai-input"
  DEFAULT_CURRENT_STATE_POLICY = :current_form_snapshot

  def add_text_suggestions(input_type:)
    super if defined?(super)

    config = ai_text_suggestions_config
    return unless config
    return if ai_input_disabled?
    return unless ai_record_ready?(config)

    integration = Folio::Ai.registry.integration(config[:integration_key])
    field = integration&.fields&.[](config[:field_key])
    return unless field&.supports_input_type?(input_type, record_class: integration.record_class)

    availability = Folio::Ai::Availability.new(site: config[:site],
                                               integration_key: config[:integration_key],
                                               field_key: config[:field_key],
                                               host_eligible: ai_host_eligible(config)).call
    return unless availability.available?

    ensure_ai_target_id
    prepare_ai_wrapper
    append_ai_custom_html(controls: ai_text_suggestions_controls(config), html: ai_text_suggestions_custom_html)
    register_stimulus(CONTROLLER_NAME,
                      wrapper: true,
                      action: {
                        "click@window": "onWindowClick",
                        "keydown@window": "onWindowKeydown",
                        "f-ai-input/message": "onMessage",
                        "f-ai-c-text-suggestions:close": "close",
                        "f-ai-c-text-suggestions:regenerate": "regenerate",
                        "f-ai-c-text-suggestions:accept": "acceptSuggestion",
                      },
                      values: ai_text_suggestions_values(config))

    input_sync_action = "input->#{CONTROLLER_NAME}#onInputSyncAiSuggestion"
    input_html_options["data-action"] = if input_html_options["data-action"].present?
      "#{input_html_options["data-action"]} #{input_sync_action}"
    else
      input_sync_action
    end
  end

  private
    def ai_text_suggestions_config
      return unless options.key?(:ai)
      return if options[:ai] == false || options[:ai].nil?

      config = case options[:ai]
               when true
                 {}
               else
                 unless options[:ai].respond_to?(:to_h)
                   raise ArgumentError, "SimpleForm ai: must be true, false, or a hash"
                 end

                 options[:ai].to_h.symbolize_keys
      end

      config[:record] = config.fetch(:record, @builder.object)
      config[:site] = config.fetch(:site, Folio::Current.site)
      config[:integration_key] = ai_integration_key(config).to_s
      config[:field_key] = config.fetch(:field_key, attribute_name).to_s
      config[:current_state_policy] = config.fetch(:current_state_policy, DEFAULT_CURRENT_STATE_POLICY).to_sym
      config
    end

    def ai_integration_key(config)
      return config[:integration_key] if config[:integration_key].present?

      if @builder.object.class.respond_to?(:table_name)
        @builder.object.class.table_name
      else
        raise ArgumentError, "SimpleForm ai: requires integration_key when it cannot be inferred"
      end
    end

    def ai_input_disabled?
      options[:disabled] ||
        options[:readonly] ||
        input_html_options[:disabled] ||
        input_html_options[:readonly]
    end

    def ai_record_ready?(config)
      return false unless %i[persisted_record current_form_snapshot].include?(config[:current_state_policy])

      record = config[:record]

      record.respond_to?(:persisted?) ? record.persisted? : record.present?
    end

    def ai_host_eligible(config)
      record = config[:record]
      return true unless record.respond_to?(:folio_ai_suggestions_eligible?)

      record.folio_ai_suggestions_eligible?(field_key: config[:field_key],
                                            current_form_snapshot: {})
    end

    def prepare_ai_wrapper
      options[:wrapper_html] ||= {}
      classes = Array(options[:wrapper_html][:class]).flat_map { |klass| klass.to_s.split }
      classes << "form-group--with-ai-text-suggestions"
      options[:wrapper_html][:class] = classes.uniq
    end

    def ensure_ai_target_id
      input_html_options[:id] ||= generated_ai_target_id
    end

    def generated_ai_target_id
      "#{@builder.object_name}_#{attribute_name}".tr("[]", "_")
                                                .squeeze("_")
                                                .delete_suffix("_")
    end

    def ai_text_suggestions_controls(config)
      template = @builder.template

      template.tag.div(class: "f-ai-input__controls") do
        template.safe_join([
          ai_text_suggestions_button(config),
          ai_text_suggestions_undo_button(config),
        ])
      end
    end

    def ai_text_suggestions_button(config)
      template = @builder.template

      template.tag.button(type: "button",
                          id: "#{ai_text_suggestions_component_id}_button",
                          class: "f-ai-input__button",
                          aria: {
                            controls: ai_text_suggestions_component_id,
                            expanded: "false",
                          },
                          data: stimulus_data(controller: CONTROLLER_NAME,
                                              action: { click: "toggle" },
                                              target: "button")) do
        template.safe_join([
          ai_text_suggestions_icon(:creation),
          content_tag(:span, nil, class: "f-ai-input__button-loader folio-loader folio-loader--tiny folio-loader--transparent"),
          template.tag.span(ai_text_suggestions_translation(:button_label, config:),
                            class: "f-ai-input__button-label"),
        ])
      end
    end

    def ai_text_suggestions_undo_button(config)
      template = @builder.template

      template.tag.button(type: "button",
                          id: "#{ai_text_suggestions_component_id}_undo",
                          class: "f-ai-input__undo",
                          hidden: true,
                          data: stimulus_data(controller: CONTROLLER_NAME,
                                              target: "undo",
                                              action: { click: "undoSuggestion" })) do
        template.safe_join([
          ai_text_suggestions_icon(:arrow_u_left_top),
          template.tag.span(ai_text_suggestions_translation(:undo_label, config:),
                            class: "f-ai-input__undo-label"),
        ])
      end
    end

    def ai_text_suggestions_icon(icon)
      template = @builder.template

      template.tag.span(class: "f-ai-input__icon", aria: { hidden: true }) do
        template.folio_icon(icon, height: 16)
      end
    end

    def ai_text_suggestions_custom_html
      @builder.template.tag.div("",
                                class: "f-ai-input__custom-html",
                                data: stimulus_data(controller: CONTROLLER_NAME,
                                                    target: "customHtml"))
    end

    def append_ai_custom_html(controls:, html:)
      options[:custom_html] = [options[:custom_html], controls, html].compact.join.html_safe
    end

    def ai_text_suggestions_values(config)
      {
        url: ai_text_suggestions_url,
        instructions_url: ai_text_suggestions_instructions_url,
        klass: config[:record].class.name,
        record_id: config[:record].id,
        integration_key: config[:integration_key],
        field_key: config[:field_key],
        suggestion_count: config.fetch(:suggestion_count, Folio::Ai::ResponseNormalizer::DEFAULT_SUGGESTION_COUNT),
        component_id: ai_text_suggestions_component_id,
        show_meta: config.fetch(:show_meta, false),
        current_state_policy: config[:current_state_policy],
        request_timeout_ms: config.fetch(:request_timeout_ms, Folio::Ai.config.client_request_timeout_ms),
        loading_text: ai_text_suggestions_translation(:loading_text, config:),
        generic_error_text: ai_text_suggestions_translation(:generic_error_text, config:),
        request_timeout_text: ai_text_suggestions_translation(:request_timeout_text, config:),
      }.compact
    end

    def ai_text_suggestions_url
      ai_route_proxy.text_suggestions_console_api_ai_text_suggestions_path
    end

    def ai_text_suggestions_instructions_url
      ai_route_proxy.instructions_console_api_ai_text_suggestions_path
    end

    def ai_route_proxy
      if @builder.template.respond_to?(:folio)
        @builder.template.folio
      else
        Folio::Engine.routes.url_helpers
      end
    end

    def ai_text_suggestions_translation(key, config:)
      config.fetch(key) do
        I18n.t(key, scope: "folio.ai.console.text_suggestions_component")
      end
    end

    def ai_text_suggestions_component_id
      "folio_ai_text_suggestions_#{input_html_options[:id].to_s.gsub(/[^a-zA-Z0-9_-]/, '_')}"
    end
end

SimpleForm::Inputs::Base.prepend(Folio::Ai::SimpleFormInputExtension)
