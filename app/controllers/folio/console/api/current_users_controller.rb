# frozen_string_literal: true

class Folio::Console::Api::CurrentUsersController < Folio::Console::Api::BaseController
  def console_url_ping
    Folio::Current.user.update_console_url!(params.require(:url))
    head 200
  end

  def update_console_preferences
    console_preferences_params = params.permit(:autosave, :html_auto_format).to_h
    console_preferences = (Folio::Current.user.console_preferences || {}).merge(console_preferences_params)

    console_preferences.each do |key, value|
      if value == "true"
        console_preferences[key] = true
      elsif value == "false"
        console_preferences[key] = false
      end
    end

    status = if Folio::Current.user.update(console_preferences:)
      :ok
    else
      :unprocessable_entity
    end

    render json: {
      data: Folio::Current.user.console_preferences || {}
    }, status:
  end
end
