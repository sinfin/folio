# frozen_string_literal: true

class Folio::Console::GroupByDayHeaderCell < Folio::ConsoleCell
  def show
    render if model[:date].present?
  end

  def count
    return @count unless @count.nil?

    date = model[:date].to_date
    @count = model[:scope].unscope(:limit, :offset)
                          .where("#{model[:attribute]} > ?",
                                 date.beginning_of_day)
                          .where("#{model[:attribute]} < ?",
                                 date.end_of_day)
                          .count
  end
end
