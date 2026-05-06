# frozen_string_literal: true

module Folio::Ai::SimpleFormInputExtension
  CONTROLLER_NAME = "f-input-ai-text-suggestions"
  DEFAULT_CURRENT_STATE_POLICY = :persisted_record

  def add_text_suggestions(input_type:)
    super if defined?(super)

    config = ai_text_suggestions_config
    return unless config
    return if ai_input_disabled?
    return unless ai_record_ready?(config)

    field = Folio::Ai.registry.field(config[:integration_key], config[:field_key])
    return unless field&.input_types&.include?(input_type.to_sym)

    availability = Folio::Ai::Availability.new(site: config[:site],
                                               integration_key: config[:integration_key],
                                               field_key: config[:field_key],
                                               host_eligible: ai_host_eligible(config)).call
    return unless availability.available?

    ensure_ai_target_id
    prepare_ai_wrapper
    register_stimulus(CONTROLLER_NAME,
                      wrapper: true,
                      action: {
                        "click@window": "onWindowClick",
                        "keydown@window": "onWindowKeydown",
                      },
                      values: ai_text_suggestions_values(config:, field:))
  end

  private
    def ai_text_suggestions_config
      return unless options.key?(:ai)
      return if options[:ai] == false || options[:ai].nil?

      unless options[:ai].respond_to?(:to_h)
        raise ArgumentError, "SimpleForm ai: requires endpoint and must be a hash"
      end

      config = options[:ai].to_h.symbolize_keys
      raise ArgumentError, "SimpleForm ai: requires endpoint" if config[:endpoint].blank?

      config[:record] = config.fetch(:record, @builder.object)
      config[:site] = config.fetch(:site, Folio::Current.site)
      config[:user] = config.fetch(:user, Folio::Current.user)
      config[:integration_key] = ai_integration_key(config).to_s
      config[:field_key] = config.fetch(:field_key, attribute_name).to_s
      config[:current_state_policy] = config.fetch(:current_state_policy, DEFAULT_CURRENT_STATE_POLICY).to_sym
      config[:host_eligible] = config.fetch(:host_eligible, true)
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
      record = config[:record]

      case config[:current_state_policy]
      when :persisted_record
        record.respond_to?(:persisted?) ? record.persisted? : record.present?
      when :current_form_snapshot
        record.present?
      else
        false
      end
    end

    def ai_host_eligible(config)
      host_eligible = config[:host_eligible]
      return host_eligible unless host_eligible.respond_to?(:call)

      host_eligible.call(field_key: config[:field_key],
                         attribute_name:,
                         record: config[:record])
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

    def ai_text_suggestions_values(config:, field:)
      {
        endpoint: config[:endpoint],
        integration_key: config[:integration_key],
        field_key: config[:field_key],
        suggestion_count: config.fetch(:suggestion_count, Folio::Ai::ResponseNormalizer::DEFAULT_SUGGESTION_COUNT),
        character_limit: ai_character_limit(field),
        initial_instructions: ai_user_instruction(config),
        field_label: config.fetch(:field_label, field.label),
        button_label: ai_text_suggestions_translation(:button_label, config:),
        undo_label: ai_text_suggestions_translation(:undo_label, config:),
        close_label: ai_text_suggestions_translation(:close_label, config:),
        panel_title: ai_panel_title(config:, field:),
        loading_text: ai_text_suggestions_translation(:loading_text, config:),
        generic_error_text: ai_text_suggestions_translation(:generic_error_text, config:),
        request_timeout_text: ai_text_suggestions_translation(:request_timeout_text, config:),
        missing_context_text: ai_text_suggestions_translation(:missing_context_text, config:),
        copy_label: ai_text_suggestions_translation(:copy_label, config:),
        copy_button_label: ai_text_suggestions_translation(:copy_button_label, config:),
        accept_label: ai_text_suggestions_translation(:accept_label, config:),
        accept_button_label: ai_text_suggestions_translation(:accept_button_label, config:),
        chars_label: ai_text_suggestions_translation(:chars_label, config:),
        instructions_placeholder: ai_text_suggestions_translation(:instructions_placeholder, config:),
        regenerate_label: ai_text_suggestions_translation(:regenerate_label, config:),
        component_id: ai_text_suggestions_component_id,
        show_meta: config.fetch(:show_meta, false),
        current_state_policy: config[:current_state_policy],
        request_timeout_ms: config.fetch(:request_timeout_ms, Folio::Ai.client_request_timeout_ms),
        sparkles_path: Folio::Ai::Icons::SPARKLES_PATH,
        undo_path: Folio::Ai::Icons::UNDO_PATH,
      }.compact
    end

    def ai_text_suggestions_translation(key, config:)
      config.fetch(key) do
        I18n.t(key, scope: "folio.ai.console.text_suggestions_component")
      end
    end

    def ai_panel_title(config:, field:)
      return config[:panel_title] if config[:panel_title].present?

      I18n.t("folio.ai.console.text_suggestions_component.panel_title_with_field",
             field: config.fetch(:field_label, field.label))
    end

    def ai_user_instruction(config)
      return config[:user_instructions].to_s if config.key?(:user_instructions)
      return "" if config[:user].blank? || config[:site].blank?

      Folio::Ai::UserInstruction.find_or_initialize_for(user: config[:user],
                                                        site: config[:site],
                                                        integration_key: config[:integration_key],
                                                        field_key: config[:field_key]).instruction.to_s
    end

    def ai_text_suggestions_component_id
      "folio_ai_text_suggestions_#{input_html_options[:id].to_s.gsub(/[^a-zA-Z0-9_-]/, '_')}"
    end

    def ai_character_limit(field)
      if options[:character_counter].is_a?(Numeric)
        options[:character_counter]
      else
        field.character_limit
      end
    end
end

SimpleForm::Inputs::Base.prepend(Folio::Ai::SimpleFormInputExtension)
