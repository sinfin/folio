# frozen_string_literal: true

class Folio::Console::Aasm::FormModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-aasm-form-modal"
  TARGET_FORM_CLASS_NAME = "f-c-aasm-form-modal-target"

  def initialize
  end

  def data
    stimulus_controller(CLASS_NAME,
                        action: {
                          "folioConsoleAasmFormModalOpen" => "openFromEvent",
                          "submit" => "onFormSubmit"
                        },
                        classes: %w[loading])
  end
end
