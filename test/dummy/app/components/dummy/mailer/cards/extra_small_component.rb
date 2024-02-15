# frozen_string_literal: true

class Dummy::Mailer::Cards::ExtraSmallComponent < ApplicationComponent
  THUMB_SIZE = "80x80#"

  def initialize(card: nil, even: false)
    @card = card
    @even = even
  end
end
