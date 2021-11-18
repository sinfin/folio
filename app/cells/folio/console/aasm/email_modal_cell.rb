# frozen_string_literal: true

class Folio::Console::Aasm::EmailModalCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  CLASS_NAME_BASE = "f-c-aasm-email-modal"
  CLASS_NAME = ".#{CLASS_NAME_BASE}"

  def show
    cell("folio/console/modal", class: CLASS_NAME_BASE,
                                body: render)
  end

  def form(&block)
    opts = {
      url: controller.folio.event_console_api_aasm_path,
      html: {
        class: "f-c-aasm-email-modal__form",
      },
    }

    simple_form_for("", opts, &block)
  end

  def key_hidden_field(f, key)
    f.hidden_field key, value: nil, class: "f-c-aasm-email-modal__hidden f-c-aasm-email-modal__hidden--#{key}"
  end
end
