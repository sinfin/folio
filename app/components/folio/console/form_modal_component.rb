# frozen_string_literal: true

class Folio::Console::FormModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-form-modal"
  TARGET_FORM_CLASS_NAME = "f-c-form-modal-target"

  def initialize
  end

  def data
    stimulus_controller(CLASS_NAME,
                        action: {
                          "folioConsoleFormModalOpen" => "openFromEvent",
                          "submit" => "onFormSubmit"
                        },
                        classes: %w[loading])
  end
end
