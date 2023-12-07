# frozen_string_literal: true

class Dummy::Ui::Input::WithIconComponent < ApplicationComponent
  def initialize(f:, name:, input_options: {}, icon: :search, type: :submit)
    @f = f
    @icon = icon
    @type = type
    @name = name
    @input_options = input_options
  end

  def custom_html
    capture do
      button_tag(dummy_ui_icon(@icon, height: 24),
                 type: @type,
                 class: "d-ui-input-with-icon__btn")
    end
  end
end
