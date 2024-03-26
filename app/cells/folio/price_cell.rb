# frozen_string_literal: true

class Folio::PriceCell < Folio::ApplicationCell
  include ActionView::Helpers::NumberHelper

  def text
    if model == "&ndash;"
      "&ndash; #{options[:currency] || t(".default_currency")}"
    elsif options[:zero_as_text] && model.zero?
      t(".free")
    else
      kwargs = {
        unit: options[:currency] || t(".default_currency"),
        precision: options[:precision] || 0,
        delimiter: " ",
      }

      kwargs[:format] = options[:format] if options[:format]

      number_to_currency(model, **kwargs)
    end
  end
end
