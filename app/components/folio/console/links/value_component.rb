# frozen_string_literal: true

class Folio::Console::Links::ValueComponent < Folio::Console::ApplicationComponent
  def initialize(url_json:,
                 record: nil,
                 verbose: true,
                 json: true,
                 disabled: false)
    @url_json = url_json
    @record = record
    @verbose = verbose
    @json = json
    @disabled = disabled
  end

  def render?
    @url_json.present? && @url_json[:href].present?
  end

  def before_render
    if @record.nil? && @url_json[:record_id].present? && @url_json[:record_type].present?
      klass = @url_json[:record_type].safe_constantize

      if klass < ActiveRecord::Base
        record = klass.find_by(id: @url_json[:record_id])

        if can_now?(:show, record)
          @record = record
        end
      end
    end

    @record_site_title = if @record.class.try(:has_belongs_to_site?)
      if @record.site && @record.site.title.present?
        @record.site.title
      end
    end
  end

  def data
    stimulus_controller("f-c-links-value",
                        values: { json: @json })
  end
end
