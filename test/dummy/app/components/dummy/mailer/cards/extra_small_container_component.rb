# frozen_string_literal: true

class Dummy::Mailer::Cards::ExtraSmallContainerComponent < ApplicationComponent
  def initialize(cards: nil)
    @cards = cards
  end
end
