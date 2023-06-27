# frozen_string_literal: true

class Folio::Console::Report::BoxCell < Folio::ConsoleCell
  def total_value
    @total_value ||= model[:total_price] || model[:total]
  end

  def formatted_total_value
    @formatted_total_value ||= if total_value
      if model[:total_price]
        folio_price(total_value)
      else
        total_value
      end
    end
  end

  def total_value_classes
    base = "f-c-report-box__total-value"

    if total_value.is_a?(Numeric)
      if total_value > 0
        "#{base} #{base}--positive"
      else
        "#{base} #{base}--negative"
      end
    else
      base
    end
  end
end
