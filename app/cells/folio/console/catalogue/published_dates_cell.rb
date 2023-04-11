# frozen_string_literal: true

class Folio::Console::Catalogue::PublishedDatesCell < Folio::ConsoleCell
  class_name "f-c-catalogue-published-dates", :success?

  def show
    render if model.present?
  end

  def success?
    if model.respond_to?(:published_at)
      model.published_at <= Time.current
    elsif model.respond_to?(:published_from) && model.respond_to?(:published_until)
      (model.published_from.nil? || model.published_from <= Time.current) &&
      (model.published_until.nil? || model.published_until >= Time.current)
    end
  end

  def pretty(date_or_nil)
    date_or_nil ? l(date_or_nil, format: :console_short) : "-"
  end
end
