# frozen_string_literal: true

class Folio::Console::Files::DisplayToggleComponent < Folio::Console::ApplicationComponent
  def initialize; end

  def buttons_data
    [
      {
        icon: :grid_view,
        class: "f-c-files-display-toggle__btn f-c-files-display-toggle__btn--enabled-false",
        data: stimulus_action({ click: "click" }, { enabled: false })
      },
      {
        icon: :format_list_bulleted,
        class: "f-c-files-display-toggle__btn f-c-files-display-toggle__btn--enabled-true",
        data: stimulus_action({ click: "click" }, { enabled: true })
      }
    ]
  end

  def data
    enabled = if Folio::Current.user && Folio::Current.user.console_preferences.present?
      Folio::Current.user.console_preferences["images_table_view"].present?
    else
      false
    end

    stimulus_controller("f-c-files-display-toggle",
                        values: {
                          api_url: controller.update_console_preferences_console_api_current_user_path,
                          enabled:
                        })
  end
end
