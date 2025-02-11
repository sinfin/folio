# frozen_string_literal: true

class Folio::Console::CurrentUsers::PreferenceToggleComponent < Folio::Console::ApplicationComponent
  def initialize(key:, label:, javascript_key:, class_name: nil)
    @key = key
    @label = label
    @javascript_key = javascript_key
    @class_name = class_name
  end

  def enabled
    return @enabled unless @enabled.nil?

    @enabled = if Folio::Current.user && Folio::Current.user.console_preferences.present?
      Folio::Current.user.console_preferences[@key]
    end

    @enabled = true if @enabled.nil?

    @enabled
  end

  def data
    stimulus_controller("f-c-current-users-preference-toggle",
                        values: {
                          api_url: controller.update_console_preferences_console_api_current_user_path,
                          enabled:,
                          key: @key,
                          javascript_key: @javascript_key,
                        },
                        action: {
                          "f-c-ui-boolean-toggle:input" => "booleanToggleInput",
                        })
  end
end
