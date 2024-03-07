# frozen_string_literal: true

class Folio::Console::Aasm::FormModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-aasm-form-modal"

  def initialize
  end

  def data
    stimulus_controller(CLASS_NAME,
                        action: {
                          "folioConsoleAasmFormModalOpen" => "openFromEvent"
                        })
  end
end
