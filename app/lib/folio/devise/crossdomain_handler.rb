# frozen_string_literal: true

class Folio::Devise::CrossdomainHandler
  attr_accessor :request,
                :session,
                :current_user,
                :current_site,
                :controller_name,
                :action_name,
                :master_site,
                :params,
                :resource_class,
                :devise_controller,
                :resource_name

  Result = Struct.new(:action, :target, :params, keyword_init: true)

  TIMESTAMP_THRESHOLD = 10.minutes
  TOKEN_LENGTH = 20
  SESSION_KEY = "folio_devise_crossdomain"

  def initialize(request:,
                 session:,
                 current_user:,
                 current_site:,
                 controller_name:,
                 action_name:,
                 params: {},
                 master_site: nil,
                 resource_name: nil,
                 resource_class: nil,
                 devise_controller: false)
    @request = request
    @session = session
    @current_user = current_user
    @current_site = current_site
    @controller_name = controller_name
    @action_name = action_name
    @params = params || {}
    @master_site = master_site || Folio.site_for_crossdomain_devise
    @resource_class = resource_class || Folio::User
    @resource_name = resource_name || :user
    @devise_controller = devise_controller
  end

  def handle_before_action!
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
      token = params[:crossdomain].presence || (session.try(:[], SESSION_KEY).try(:[], "token").presence)
      token = nil if token && token.length != TOKEN_LENGTH

      target_site_slug = params[:site].presence || (session.try(:[], SESSION_KEY).try(:[], "target_site_slug").presence)

      if token && target_site_slug
        # valid params or session
        if current_user
          current_user.update_columns(crossdomain_devise_token: Devise.friendly_token[0, TOKEN_LENGTH],
                                      crossdomain_devise_set_at: Time.current)

          clear_session!

          target_site = Folio::Site.find_by_slug(target_site_slug)

          # be able to test in folio dummy app with singleton sites
          target_site ||= Folio::Site.instance if Rails.env.test?

          Result.new(action: :sign_in_on_target_site,
                            params: {
                              crossdomain: token,
                              crossdomain_user: current_user.crossdomain_devise_token,
                              host: target_site.env_aware_domain,
                              only_path: false,
                            })
        else
          session[SESSION_KEY] = { target_site_slug:, token: }
          Result.new(action: :redirect_to_sessions_new)
        end
      else
        # invalid or blank params and session
        Result.new(action: :noop)
      end
    end

    def handle_on_slave_site!
      return Result.new(action: :noop) if current_user

      if params[:crossdomain].present? && params[:crossdomain_user].present?
        session_token = session.try(:[], SESSION_KEY).try(:[], "token")
        session_timestamp = session.try(:[], SESSION_KEY).try(:[], "timestamp")

        if params[:crossdomain] == session_token &&
           session_timestamp &&
           session_timestamp > TIMESTAMP_THRESHOLD.ago &&
           params[:crossdomain_user].length == TOKEN_LENGTH
          user = Folio::User.where("crossdomain_devise_set_at > ?", TIMESTAMP_THRESHOLD.ago)
                            .find_by(crossdomain_devise_token: params[:crossdomain_user])


          if user
            clear_session!
            return Result.new(action: :sign_in, target: user)
          end
        end
      end

      if devise_controller
        set_slave_session_before_redirect

        result_params = {
          only_path: false,
          host: master_site.env_aware_domain,
          crossdomain: session[SESSION_KEY][:token],
          site: current_site.slug,
        }

        if %w[registrations invitations].include?(controller_name)
          return Result.new(action: :redirect_to_master_invitations_new,
                            params: result_params)
        else
          return Result.new(action: :redirect_to_master_sessions_new,
                            params: result_params)
        end
      end

      Result.new(action: :noop)
    end

    def has_crossdomain_data_in_session?
      !!session[SESSION_KEY]
    end

    def clear_session!
      session.delete(SESSION_KEY)
    end

    def set_slave_session_before_redirect
      session[SESSION_KEY] = {
        token: Devise.friendly_token[0, TOKEN_LENGTH],
        timestamp: Time.current,
      }
    end
end
