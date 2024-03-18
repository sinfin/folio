# frozen_string_literal: true

class Dummy::Mailer::Cards::ExtraSmallContainerComponent < ApplicationComponent
  def initialize(cards:)
    @cards = cards
  end

  def render?
    @cards.present?
  end
end
