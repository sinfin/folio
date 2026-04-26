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

    target_id = ensure_ai_target_id
    component_id = ai_text_suggestions_component_id(target_id)

    mark_ai_wrapper
    append_input_control(ai_text_suggestions_controls(component_id:))
    append_custom_html(ai_text_suggestions_component(context:,
                                                     field:,
                                                     target_id:,
                                                     component_id:))
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

    def ai_text_suggestions_component(context:, field:, target_id:, component_id:)
      @builder.template.render(Folio::Console::Ai::TextSuggestionsComponent.new(
        id: component_id,
        integration_key: context.integration_key,
        field_key: field.key,
        endpoint: context.endpoint,
        target_selector: "##{target_id}",
        user_instructions: context.user_instruction_for(field_key: field.key),
        character_limit: ai_character_limit(field),
        field_label: field.label,
        class_name: "f-c-ai-text-suggestions--auto-attached",
        external_controls: true,
        external_button_selector: "##{component_id}_button",
        external_undo_selector: "##{component_id}_undo"
      ))
    end

    def ai_text_suggestions_controls(component_id:)
      template = @builder.template

      template.tag.div(class: "f-c-ai-text-suggestions f-c-ai-text-suggestions--external-actions") do
        template.tag.div(class: "f-c-ai-text-suggestions__actions") do
          template.safe_join([
            ai_text_suggestions_button(component_id:),
            ai_text_suggestions_undo(component_id:),
          ])
        end
      end
    end

    def ai_text_suggestions_button(component_id:)
      template = @builder.template

      template.tag.button(type: "button",
                          id: "#{component_id}_button",
                          class: "f-c-ai-text-suggestions__button",
                          aria: { expanded: "false", controls: component_id },
                          data: ai_click_trigger_data("##{component_id} .f-c-ai-text-suggestions__button")) do
        template.safe_join([
          ai_text_suggestions_sparkles_icon(template),
          template.tag.span(I18n.t("folio.console.ai.text_suggestions_component.button_label"),
                            class: "f-c-ai-text-suggestions__button-label"),
        ])
      end
    end

    def ai_text_suggestions_undo(component_id:)
      template = @builder.template

      template.tag.button(type: "button",
                          id: "#{component_id}_undo",
                          class: "f-c-ai-text-suggestions__undo",
                          hidden: true,
                          data: ai_click_trigger_data("##{component_id} .f-c-ai-text-suggestions__undo")) do
        template.safe_join([
          ai_text_suggestions_undo_icon(template),
          template.tag.span(I18n.t("folio.console.ai.text_suggestions_component.undo_label"),
                            class: "f-c-ai-text-suggestions__undo-label"),
        ])
      end
    end

    def ai_text_suggestions_sparkles_icon(template)
      Folio::Ai::Icons.sparkles(template)
    end

    def ai_text_suggestions_undo_icon(template)
      Folio::Ai::Icons.undo(template)
    end

    def ai_click_trigger_data(target)
      {
        controller: "f-click-trigger",
        "f-click-trigger-target-value": target,
      }
    end

    def mark_ai_wrapper
      options[:wrapper_html] ||= {}
      classes = Array(options[:wrapper_html][:class]).flat_map { |klass| klass.to_s.split }
      classes << "form-group--with-ai-text-suggestions"
      options[:wrapper_html][:class] = classes.uniq
    end

    def append_custom_html(html)
      options[:custom_html] = [options[:custom_html], html].compact.join.html_safe
    end

    def ensure_ai_target_id
      input_html_options[:id] ||= generated_ai_target_id
    end

    def generated_ai_target_id
      "#{@builder.object_name}_#{attribute_name}".tr("[]", "_")
                                              .squeeze("_")
                                              .delete_suffix("_")
    end

    def ai_text_suggestions_component_id(target_id)
      "folio_ai_text_suggestions_#{target_id.gsub(/[^a-zA-Z0-9_-]/, '_')}"
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
