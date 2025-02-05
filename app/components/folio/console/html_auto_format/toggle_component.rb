# frozen_string_literal: true

class Folio::Console::HtmlAutoFormat::ToggleComponent < Folio::Console::ApplicationComponent
  def initialize; end

  def data
    enabled = if Folio::Current.user && Folio::Current.user.console_preferences.present?
      Folio::Current.user.console_preferences["html_auto_format"]
    end

    enabled = true if enabled.nil?

    stimulus_controller("f-c-html-auto-format-toggle",
                        values: {
                          api_url: controller.update_console_preferences_console_api_current_user_path,
                          enabled:,
                        })
  end
end
