# frozen_string_literal: true

class Folio::Console::Catalogue::PublishedDatesComponent < Folio::Console::ApplicationComponent
  bem_class_name :success, :danger

  def initialize(record:)
    @record = record
  end

  def render?
    @record.present?
  end

  def pretty(date_or_nil)
    date_or_nil ? l(date_or_nil, format: :console_short) : "-"
  end

  def range?
    @record.respond_to?(:published_from) && @record.respond_to?(:published_until)
  end

  def published_at?
    @record.respond_to?(:published_at)
  end

  private
    def before_render
      return if @record.blank?

      @success = compute_success?
      @danger = compute_danger?
    end

    def compute_success?
      return false unless @record.read_attribute(:published)

      if @record.respond_to?(:published_at)
        @record.published_at.nil? || @record.published_at <= Time.current
      elsif @record.respond_to?(:published_from) && @record.respond_to?(:published_until)
        (@record.published_from.nil? || @record.published_from <= Time.current) &&
          (@record.published_until.nil? || @record.published_until >= Time.current)
      else
        false
      end
    end

    def compute_danger?
      return false unless @record.read_attribute(:published)

      !@success
    end
end
