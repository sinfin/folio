# frozen_string_literal: true

class Folio::Devise::Crossdomain
  attr_accessor :request,
                :session,
                :current_user,
                :current_site,
                :master_site,
                :params

  Result = Struct.new(:action, :target, :params, keyword_init: true)

  TIMESTAMP_THRESHOLD = 10.minutes
  TOKEN_LENGTH = 20
  SESSION_KEY = "folio_devise_crossdomain"

  def initialize(request:, session:, current_user:, current_site:, params: {}, master_site: nil)
    @request = request
    @session = session
    @current_user = current_user
    @current_site = current_site
    @params = params
    @master_site = master_site || Folio.site_for_crossdomain_devise
  end

  def handle!
    return Result.new(action: :noop) unless supports_crossdomain_devise?

    if current_site == master_site
      handle_on_master_site!
    else
      handle_on_slave_site!
    end
  end

  private
    def supports_crossdomain_devise?
      !!master_site
    end

    def handle_on_master_site!
      token = params[:crossdomain].presence || (session.try(:[], SESSION_KEY).try(:[], :crossdomain).presence)
      token = nil if token && token.length != TOKEN_LENGTH

      target_site_slug = params[:site].presence || (session.try(:[], SESSION_KEY).try(:[], :target_site_slug).presence)

      if token && target_site_slug
        # valid params or session
        if current_user
          current_user.update_columns(crossdomain_devise_token: Devise.friendly_token[0, TOKEN_LENGTH],
                                      crossdomain_devise_set_at: Time.current)

          session.delete(SESSION_KEY)

          return Result.new(action: :sign_in_on_target_site,
                            params: {
                              crossdomain: token,
                              crossdomain_user: current_user.crossdomain_devise_token,
                            })
        else
          session[SESSION_KEY] = { target_site_slug:, token: }
          return Result.new(action: :redirect_to_sessions_new)
        end
      else
        # invalid or blank params and session
        Result.new(action: :noop)
      end
    end

    def handle_on_slave_site!
      Result.new(action: :noop)
    end

    def has_crossdomain_data_in_session?
      !!session[SESSION_KEY]
    end
end
