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
      placement = verified_placement
      return nil if placement.nil?

      # bind the rendered bar to the pinged presence URL: the token was signed by
      # the page for this exact record + URL, so a client cannot ask for a bar of
      # record B while colliding on record A
      return nil unless placement["url"] == params[:url]

      # only resolve to an ActiveRecord model — the class guard avoids calling
      # find_by on a real but non-AR constant (e.g. "String")
      klass = placement["type"].to_s.safe_constantize
      return nil unless klass.is_a?(Class) && klass < ActiveRecord::Base

      klass.find_by(id: placement["id"])
    end

    # The placement is a signed assertion from the page (see PresencePingComponent)
    # carrying { type, id, url }. Trusting it avoids re-deriving the edit URL from
    # the record, which the API cannot do for nested console routes that need a
    # parent id the API request does not carry.
    def verified_placement
      token = params[:placement_token]
      return nil if token.blank?

      Rails.application.message_verifier(
        Folio::Console::CurrentUsers::PresencePingComponent::PLACEMENT_VERIFIER_PURPOSE
      ).verify(token)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
end
