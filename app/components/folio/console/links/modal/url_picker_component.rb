# frozen_string_literal: true

class Folio::Console::Links::Modal::UrlPickerComponent < Folio::Console::ApplicationComponent
  def initialize(url_json:)
    @url_json = url_json
  end

  def before_render
    if @record.nil? && @url_json[:record_id].present? && @url_json[:record_type].present?
      klass = @url_json[:record_type].safe_constantize

      if klass < ActiveRecord::Base
        record = klass.find_by(id: @url_json[:record_id])

        if can_now?(:read, record)
          @record = record
        end
      end
    end
  end

  def tabs
    @tabs ||= begin
      first_active = @record.present? || @url_json[:href].blank?

      [
        { label: t(".tab/pick"), key: :pick, active: first_active },
        { label: t(".tab/custom_url"), key: :custom_url, active: !first_active }
      ]
    end
  end
end
