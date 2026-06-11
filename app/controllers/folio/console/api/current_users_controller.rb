# frozen_string_literal: true

class Folio::Console::Api::CurrentUsersController < Folio::Console::Api::BaseController
  def console_url_ping
    url = params.require(:url)
    Folio::Current.user.update_console_url!(url)

    other_user_at_url = Folio::User.currently_editing_url(url)
                                   .where.not(id: Folio::Current.user.id)
                                   .exists?

    data = { other_user_at_url: }

    # when another editor appears, hand the first editor a freshly rendered
    # warning bar so it can be shown live without a full page reload (CS-337)
    if other_user_at_url
      bar_html = render_presence_bar
      data[:bar_html] = bar_html if bar_html.present?
    end

    render json: { data: }
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

  private
    # The warning bar queries presence by this URL; the client posts the same
    # canonical record presence URL, so reuse it for a consistent match.
    def folio_console_presence_url
      params[:url]
    end
    helper_method :folio_console_presence_url

    def render_presence_bar
      record = presence_bar_record
      return nil if record.nil?
      # render only what the user could edit anyway, matching the edit page's
      # own authorization (and implicitly the record's site scope)
      return nil unless can_now?(:update, record)

      render_to_string(Folio::Console::CurrentUsers::ConsoleUrlBarComponent.new(show: true, record:),
                       layout: false)
    end

    def presence_bar_record
      placement = params[:placement]
      return nil if placement.blank?

      type = placement[:type].to_s
      id = placement[:id]
      return nil if type.blank? || id.blank?

      # only resolve to an ActiveRecord model — safe_constantize avoids raising on
      # unknown constants, and the class guard avoids calling find_by on a real
      # but non-AR constant (e.g. "String")
      klass = type.safe_constantize
      return nil unless klass.is_a?(Class) && klass < ActiveRecord::Base

      record = klass.find_by(id:)
      return nil if record.nil?

      # bind the rendered bar to the pinged presence URL: the record's edit path
      # must match the URL the heartbeat reported, otherwise a client could ask
      # for a bar of record B while colliding on record A
      return nil unless presence_url_matches_record?(record)

      record
    end

    def presence_url_matches_record?(record)
      URI(params[:url].to_s).path.presence == polymorphic_path([:edit, :console, record])
    rescue URI::InvalidURIError, ActionController::UrlGenerationError, NoMethodError
      false
    end
end
