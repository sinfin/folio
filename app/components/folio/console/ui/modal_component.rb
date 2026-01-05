# frozen_string_literal: true

class Folio::Console::Ui::ModalComponent < Folio::Console::ApplicationComponent
  renders_one :header
  renders_one :footer

  def initialize(class_name:,
                 buttons_model: nil,
                 title: nil,
                 data: nil,
                 size: nil,
                 open: false,
                 align_close_with_buttons: false)
    @class_name = class_name
    @buttons_model = buttons_model
    @title = title
    @data = data
    @size = size
    @open = open
    @align_close_with_buttons = align_close_with_buttons
  end

  def close_button
    data = stimulus_controller("f-modal-close", action: { click: :click }).merge("bs-dismiss" => "modal")

    button_class_names = ["f-c-ui-modal__close"]

    if @align_close_with_buttons
      button_class_names << "f-c-ui-modal__close--aligned-with-buttons"
    end


    button_tag(folio_icon(:close),
               class: button_class_names.join(" "),
               type: "button",
               data:)
  end

  def modal_data
    stimulus_modal(open: @open)
  end
end
