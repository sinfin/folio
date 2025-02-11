# frozen_string_literal: true

class Folio::Console::Autosave::ToggleComponent < Folio::Console::ApplicationComponent
  def initialize(record:)
    @record = record
  end

  def render?
    @record.respond_to?(:folio_autosave_enabled?) && @record.folio_autosave_enabled?
  end

  def data
    stimulus_controller("f-c-autosave-toggle",
                        values: {
                          api_url: controller.update_console_preferences_console_api_current_user_path,
                          enabled:,
                        },
                        action: {
                          "f-c-ui-boolean-toggle:input" => "booleanToggleInput",
                        })
  end

  def enabled
    return @enabled unless @enabled.nil?

    @enabled = if Folio::Current.user && Folio::Current.user.console_preferences.present?
      Folio::Current.user.console_preferences["autosave"]
    end

    @enabled = true if @enabled.nil?

    @enabled
  end
end
