# frozen_string_literal: true

class Dummy::Mailer::OrderSummaryComponent < Dummy::Mailer::BaseComponent
  include Folio::PriceHelper

  THUMB_SIZE = "70x70"

  def initialize(items:, total_price: nil)
    @title = title
    @items = items
    @total_price = total_price
  end

  def render?
    @items.present?
  end
end
