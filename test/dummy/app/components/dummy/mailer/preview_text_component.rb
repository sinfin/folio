# frozen_string_literal: true

class Dummy::Mailer::PreviewTextComponent < ApplicationComponent
  def initialize(text: nil)
    @text = text
  end

  def preview_text
    if @text.present?
      @text
    else
      "Some hidden preview text. Should be minimal 90 characters long. Lorem ipsum dolor sit amet, lorem ipsum"
    end
  end
end
