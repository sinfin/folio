# frozen_string_literal: true

class Folio::PriceCell < Folio::ApplicationCell
  include ActionView::Helpers::NumberHelper

  def show
    if model == "&ndash;"
      "&ndash; #{options[:currency] || t(".default_currency")}"
    elsif options[:zero_as_text] && model.zero?
      t(".free")
    else
      number_to_currency(model,
                         unit: options[:currency] || t(".default_currency"),
                         precision: options[:precision] || 0,
                         delimiter: " ")
    end
  end
end
