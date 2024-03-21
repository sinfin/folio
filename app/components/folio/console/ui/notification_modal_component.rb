# frozen_string_literal: true

class Folio::Console::Ui::NotificationModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-ui-notification-modal"

  def data
    stimulus_controller(CLASS_NAME,
                        action: {
                          "f-modal:closed" => "onModalClose"
                        })
  end
end
