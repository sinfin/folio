# frozen_string_literal: true

class Folio::Console::GroupByDayHeaderCell < Folio::ConsoleCell
  def show
    render if model[:date].present?
  end

  def records
    return @records unless @records.nil?

    date = model[:date].to_date
    @records = model[:scope].select do |record|
      record.send(model[:attribute]).to_date == date
    end
  end
end
