# frozen_string_literal: true

class Folio::Console::Catalogue::DateComponent < Folio::Console::ApplicationComponent
  bem_class_name :alert

  def initialize(value:, alert_threshold: nil)
    @value = value
    @alert_threshold = alert_threshold
  end

  def render?
    @value.present?
  end

  def time?
    @value.is_a?(Time)
  end

  private
    def before_render
      @alert = if @alert_threshold
        @value < @alert_threshold.ago
      else
        false
      end
    end
end
