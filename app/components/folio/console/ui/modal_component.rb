# frozen_string_literal: true

class Folio::Console::Ui::ModalComponent < Folio::Console::ApplicationComponent
  renders_one :header
  renders_one :footer

  def initialize(class_name:, buttons_model: nil, title: nil, data: nil, size: nil)
    @class_name = class_name
    @buttons_model = buttons_model
    @title = title
    @data = data
    @size = size
  end

  def close_button
    data = stimulus_controller("f-modal-close", action: { click: :click }).merge("bs-dismiss" => "modal")

    button_tag(folio_icon(:close),
               class: "f-c-ui-modal__close",
               type: "button",
               data:)
  end
end
