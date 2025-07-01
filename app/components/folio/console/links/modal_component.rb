# frozen_string_literal: true

class Folio::Console::Links::ModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-links-modal"

  def initialize
  end

  def data
    stimulus_controller(CLASS_NAME,
                        values: {
                          loading: true,
                          json: true,
                          api_url: controller.modal_form_console_api_links_path,
                        },
                        action: {
                          "f-c-links-modal-form:close" => "close",
                          "f-c-links-modal-form:submit" => "submit",
                          "f-c-links-modal:open" => "onOpen",
                          "f-modal:closed" => "onModalClosed",
                        })
  end
end
