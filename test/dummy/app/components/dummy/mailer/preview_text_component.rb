# frozen_string_literal: true

class Dummy::Mailer::PreviewTextComponent < ApplicationComponent
  def initialize(text:)
    @text = text
  end

  def render?
    @text.present?
  end
end
