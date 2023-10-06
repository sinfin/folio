# frozen_string_literal: true

class Dummy::Ui::ModalComponent < ApplicationComponent
  renders_one :header
  renders_one :footer

  def initialize(class_name:, buttons_model: nil, title: nil)
    @class_name = class_name
    @buttons_model = buttons_model
    @title = title
  end

  def close_button
    data = stimulus_controller("f-modal-close", action: { click: :click }).merge("bs-dismiss" => "modal")

    button_tag(dummy_ui_icon(:close),
               class: "d-ui-modal__close",
               type: "button",
               data:)
  end
end
