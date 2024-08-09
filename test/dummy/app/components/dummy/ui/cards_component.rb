# frozen_string_literal: true

class Dummy::Ui::CardsComponent < ApplicationComponent
  def initialize(cards:)
    @cards = cards
  end
end
