# frozen_string_literal: true

class Dummy::Mailer::Cards::ExtraSmallContainerComponent < ApplicationComponent
  def initialize(cards:)
    @cards = cards
  end

  def render?
    @cards.present?
  end

  def card_wrapper_class(index)
    if index.even?
      "d-mailer-cards-extra-small-container__card-wrapper--even xs-card-even-col"
    else
      "d-mailer-cards-extra-small-container__card-wrapper--odd xs-card-odd-col"
    end
  end
end
