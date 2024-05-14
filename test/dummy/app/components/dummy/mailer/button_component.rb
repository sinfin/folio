# frozen_string_literal: true

class Dummy::Mailer::ButtonComponent < ApplicationComponent
  def initialize(label:, href:, variant: "primary", size: "md")
    @label = label
    @href = href
    @variant = variant
    @size = size
  end
end
