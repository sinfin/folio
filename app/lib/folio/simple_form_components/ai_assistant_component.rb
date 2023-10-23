# frozen_string_literal: true

module Folio
  module SimpleFormComponents
    module AiAssistantComponent
      def ai_assistant_modal_toggle(wrapper_options = nil)
        trigger_class_name = Folio::Console::AiAssistant::ModalCell::TRIGGER_CLASS_NAME
        button_class_name = "form-ai-assistant-button"
        label = I18n.t("simple_form.ai_assistant.model_toggle_label")
        prompt = options[:ai_assistant_prompt]

        %{
          <button type="button" class="#{button_class_name} #{trigger_class_name}" data-prompt="#{prompt}">
            <span>#{label}</span>
          </button>
        }.html_safe
      end
    end
  end
end

SimpleForm.include_component(Folio::SimpleFormComponents::AiAssistantComponent)
