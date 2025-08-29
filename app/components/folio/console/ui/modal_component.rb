# frozen_string_literal: true

class Folio::Console::Ui::ModalComponent < Folio::Console::ApplicationComponent
  renders_one :header
  renders_one :footer

  def initialize(class_name:, buttons_model: nil, title: nil, data: nil, size: nil, open: false)
    @class_name = class_name
    @buttons_model = buttons_model
    @title = title
    @data = data
    @size = size
    @open = open
  end

  def close_button
    data = stimulus_controller("f-modal-close", action: { click: :click }).merge("bs-dismiss" => "modal")

    button_tag(folio_icon(:close),
               class: "f-c-ui-modal__close",
               type: "button",
               data:)
  end

  def modal_data
    stimulus_modal(open: @open)
  end
end
