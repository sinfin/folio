# frozen_string_literal: true

class Dummy::Ui::ClipboardComponent < ApplicationComponent
  def initialize(text: nil, height: nil)
    @text = text
    @height = height
  end

  def data
    stimulus_controller("d-ui-clipboard",
                        classes: %w[copied])
  end
end
