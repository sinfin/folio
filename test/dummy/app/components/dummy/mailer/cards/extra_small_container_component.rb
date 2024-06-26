# frozen_string_literal: true

class Dummy::Mailer::Cards::ExtraSmallContainerComponent < Dummy::Mailer::BaseComponent
  def initialize(cards:)
    @cards = cards
  end

  def render?
    @cards.present?
  end

  def card_wrapper_class(index)
    if index.even?
      "d-mailer-cards-extra-small-container__even-column"
    else
      "d-mailer-cards-extra-small-container__odd-column"
    end
  end
end
