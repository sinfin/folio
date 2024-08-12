# frozen_string_literal: true

class Dummy::Ui::CardsComponent < ApplicationComponent
  def initialize(cards:, class_name: nil)
    @cards = cards
    @class_name = class_name
  end
end
