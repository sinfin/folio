# frozen_string_literal: true

class Folio::Console::Api::CurrentUsersController < Folio::Console::Api::BaseController
  def console_url_ping
    url = params.require(:url)
    Folio::Current.user.update_console_url!(url)

    other_user_at_url = Folio::User.currently_editing_url(url)
                                   .where.not(id: Folio::Current.user.id)
                                   .exists?

    render json: { data: { other_user_at_url: } }
  end

  def console_url_clear
    Folio::Current.user.clear_console_url!(only_if_url: params.require(:url))
    head 204
  end

  def update_console_preferences
    console_preferences_params = params.permit(:autosave,
                                               :html_auto_format,
                                               :images_table_view)

    console_preferences = (Folio::Current.user.console_preferences || {}).merge(console_preferences_params.to_h)

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
