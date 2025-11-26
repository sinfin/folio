# frozen_string_literal: true

class Folio::Console::Form::WarningsComponent < Folio::Console::ApplicationComponent
  def initialize(warnings:, record_key: nil)
    @warnings = warnings
    @record_key = record_key
  end

  def notification
    t(".notification")
  end

  def data
    stimulus_controller("f-c-form-warnings",
                        values: {
                          record_key: @record_key,
                        },
                        action: {
                          "submit@document" => "show"
                        })
  end
end
