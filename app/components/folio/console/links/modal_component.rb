# frozen_string_literal: true

class Folio::Console::Links::ModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-links-modal"

  def initialize
  end

  def data
    stimulus_controller(CLASS_NAME)
  end

  def buttons_model
    [
      {
        variant: :gray,
        label: t(".cancel"),
        data: stimulus_action("onCancelClick")
      },
      {
        variant: :primary,
        type: :submit,
        label: t(".submit"),
      },
    ]
  end
end
