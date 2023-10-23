# frozen_string_literal: true

class Folio::Console::AiAssistant::ModalCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  CLASS_NAME_BASE = "f-c-ai-assistant-modal"
  CLASS_NAME = ".#{CLASS_NAME_BASE}"

  TRIGGER_CLASS_NAME = "#{CLASS_NAME_BASE}-trigger"

  def show
    cell("folio/console/modal", class: CLASS_NAME_BASE,
                                body: render)
  end

  def form(&block)
    opts = {
      url: form_action,
      html: {
        class: "f-c-ai-assistant-modal__form",
      },
    }

    simple_form_for("", opts, &block)
  end

  def form_action
    controller.folio.generate_response_console_api_ai_assistant_path(record_id: model.id,
                                                                     record_klass: model.class)
  end

  def edit_prompt_action
    options[:edit_prompt_action]
  end
end
