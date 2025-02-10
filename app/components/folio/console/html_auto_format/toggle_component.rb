# frozen_string_literal: true

class Folio::Console::HtmlAutoFormat::ToggleComponent < Folio::Console::ApplicationComponent
  def initialize; end

  def enabled
    return @enabled unless @enabled.nil?

    @enabled = if Folio::Current.user && Folio::Current.user.console_preferences.present?
      Folio::Current.user.console_preferences["html_auto_format"]
    end

    @enabled = true if @enabled.nil?

    @enabled
  end

  def data
    stimulus_controller("f-c-html-auto-format-toggle",
                        values: {
                          api_url: controller.update_console_preferences_console_api_current_user_path,
                          enabled:,
                        },
                        action: {
                          "f-c-ui-boolean-toggle:input" => "booleanToggleInput",
                        })
  end
end
