# frozen_string_literal: true

module Folio::Ai::SimpleFormInputExtension
  def add_text_suggestions(input_type:)
    super if defined?(super)

    context = folio_ai_form_context
    return unless context&.record_ready?

    field = Folio::Ai.registry.field(context.integration_key, attribute_name)
    return unless field&.auto_attach?
    return unless field.input_types.include?(input_type.to_sym)
    return if ai_input_disabled?

    availability = context.availability_for(field_key: attribute_name,
                                            attribute_name: attribute_name)
    return unless availability.available?

    append_input_control(ai_text_suggestions_component(context:, field:))
  end

  private
    def folio_ai_form_context
      template = @builder.template

      if template.respond_to?(:current_folio_ai_form_context, true)
        template.send(:current_folio_ai_form_context)
      else
        template.instance_variable_get(:@folio_ai_form_context)
      end
    end

    def ai_input_disabled?
      options[:disabled] ||
        options[:readonly] ||
        input_html_options[:disabled] ||
        input_html_options[:readonly]
    end

    def ai_text_suggestions_component(context:, field:)
      target_id = ensure_ai_target_id

      @builder.template.render(Folio::Console::Ai::TextSuggestionsComponent.new(
        integration_key: context.integration_key,
        field_key: field.key,
        endpoint: context.endpoint,
        target_selector: "##{target_id}",
        user_instructions: context.user_instruction_for(field_key: field.key),
        character_limit: ai_character_limit(field),
        field_label: field.label
      ))
    end

    def ensure_ai_target_id
      input_html_options[:id] ||= generated_ai_target_id
    end

    def generated_ai_target_id
      "#{@builder.object_name}_#{attribute_name}".tr("[]", "_")
                                              .squeeze("_")
                                              .delete_suffix("_")
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
