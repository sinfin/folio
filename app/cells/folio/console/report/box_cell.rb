# frozen_string_literal: true

class Folio::Console::Report::BoxCell < Folio::ConsoleCell
  def total_value
    @total_value ||= model[:total_price] || model[:total]
  end

  def formatted_total_value
    @formatted_total_value ||= if total_value
      if total_value.zero?
        folio_price("&ndash;")
      elsif model[:total_price]
        folio_price(total_value)
      else
        total_value
      end
    end
  end

  def total_value_classes
    if total_value.is_a?(Numeric) && total_value > 0
      "text-success"
    elsif total_value.is_a?(Numeric) && total_value < 0
      "text-danger"
    else
      "text-muted"
    end
  end
end
