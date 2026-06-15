# frozen_string_literal: true

class Folio::Console::Api::CurrentUsersController < Folio::Console::Api::BaseController
  def console_presence_ping
    record = presence_record
    Folio::Current.user.touch_console_active!

    if record.nil?
      return render json: { data: { other_user_at_url: false } }
    end

    Folio::Current.user.touch_console_presence!(record)

    other = Folio::ConsolePresence.others_editing(record, except_user_id: Folio::Current.user.id)
                                  .exists?
    data = { other_user_at_url: other }
    data[:bar_html] = render_presence_bar(record) if other

    render json: { data: }
  end

  def console_presence_clear
    record = presence_record
    Folio::Current.user.clear_console_presence!(record) if record
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

  private
    # Resolve the edited record from the heartbeat payload. Only AR models the
    # current user may edit are accepted — so no signed token is needed.
    def presence_record
      type = params[:record_type].to_s
      id = params[:record_id]
      return nil if type.blank? || id.blank?

      klass = type.safe_constantize
      return nil unless klass.is_a?(Class) && klass < ActiveRecord::Base

      record = klass.find_by(id:)
      return nil if record.nil?
      return nil unless can_now?(:update, record)

      record
    end

    def render_presence_bar(record)
      render_to_string(Folio::Console::CurrentUsers::ConsoleUrlBarComponent.new(show: true, record:),
                       layout: false)
    end
end
