# frozen_string_literal: true

class Folio::Console::AiAssistant::ModalCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

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
        data: { count_tokens_url: }
      },
    }

    simple_form_for("", opts, &block)
  end

  def response_data
    {
      use_response_text: t(".use_response_text"),
    }
  end

  def form_action
    controller.folio.generate_response_console_api_ai_assistant_path(record_id: model.id,
                                                                     record_klass: model.class)
  end

  def count_tokens_url
    controller.folio.count_prompt_tokens_console_api_ai_assistant_path(record_id: model.id,
                                                                       record_klass: model.class)
  end

  def edit_prompt_action
    options[:edit_prompt_action]
  end

  def gpt_models
    Folio::ChatGptClient.allowed_models_for_select
  end

  def ai_assistant_substitute_patterns
    model.class.try(:ai_assistant_substitute_patterns) || []
  end

  def prompt_substitute_patterns_hints
    @prompt_substitute_patterns ||= ai_assistant_substitute_patterns.map do |pattern_data|
      [pattern_data[:pattern], pattern_data[:hint]].join(" ")
    end
  end
end
