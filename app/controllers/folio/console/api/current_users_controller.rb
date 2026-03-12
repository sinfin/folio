# frozen_string_literal: true

class Folio::Console::Api::CurrentUsersController < Folio::Console::Api::BaseController
  def console_url_ping
    console_url = params.require(:url)
    Folio::Current.user.update_console_url!(console_url)

    show_console_bar = console_url.ends_with?("/edit") && other_user_on_same_url?(console_url)
    if show_console_bar
      record = params.require(:record_type).constantize.find(params.require(:record_id))
      render json: {
        data: render_to_string(Folio::Console::CurrentUsers::ConsoleUrlBarComponent.new(show: true, record:, console_url:))
      }, status: :ok
    else
      head 204
    end
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

  private
    def other_user_on_same_url?(url)
      Folio::User.currently_editing_url(url).where.not(id: Folio::Current.user.id).first.present?
    end
end
