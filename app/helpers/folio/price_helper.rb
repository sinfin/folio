# frozen_string_literal: true

module Folio::PriceHelper
  def folio_price(number, price_options = {})
    base = if respond_to?(:cell)
      cell("folio/price", number, price_options)
    else
      Folio::PriceCell.new(number, price_options)
    end

    base.show.html_safe
  end
end
