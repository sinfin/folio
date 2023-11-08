# frozen_string_literal: true

class Dummy::Ui::InputWithButtonComponent < ApplicationComponent
  def initialize(f:, attribute:, input_options:, button_model:)
    @f = f
    @attribute = attribute
    @input_options = input_options
    @button_model = button_model
  end
end
