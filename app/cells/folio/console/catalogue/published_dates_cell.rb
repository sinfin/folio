# frozen_string_literal: true

class Folio::Console::Catalogue::PublishedDatesCell < Folio::ConsoleCell
  class_name "f-c-catalogue-published-dates", :success?, :danger?

  def show
    render if model.present?
  end

  def success?
    return @success unless @success.nil?
    return false unless model.read_attribute(:published)

    if model.respond_to?(:published_at)
      @success = model.published_at.nil? || model.published_at <= Time.current
    elsif model.respond_to?(:published_from) && model.respond_to?(:published_until)
      @success = (model.published_from.nil? || model.published_from <= Time.current) &&
                 (model.published_until.nil? || model.published_until >= Time.current)
    else
      @success = false
    end
  end

  def danger?
    return false unless model.read_attribute(:published)
    !success?
  end

  def pretty(date_or_nil)
    date_or_nil ? l(date_or_nil, format: :console_short) : "-"
  end
end
