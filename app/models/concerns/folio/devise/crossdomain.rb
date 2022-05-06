# frozen_string_literal: true

module Folio::Devise::Crossdomain
  TIMESTAMP_THRESHOLD = 10.minutes
  TOKEN_LENGTH = 20
  SESSION_KEY = "crossdomain_devise"

  module ApplicationControllerConcern
    included do
      before_action :handle_crossdomain_devise
    end

    private
      def handle_crossdomain_devise
        return unless site_for_crossdomain_devise

        if current_site == site_for_crossdomain_devise
          handle_crossdomain_devise_on_master
        else
          handle_crossdomain_devise_on_slave
        end
      end

      def handle_crossdomain_devise_on_slave
        Rails.logger.debug "#{request.host} - handle_crossdomain_devise_on_slave"

        if user = user_to_sign_in_on_slave
          sign_in_user_from_crossdomain!(user)
        else
          Rails.logger.debug "#{request.host} - handle_crossdomain_devise_on_slave - no user"
          pp = request.path_parameters
          token = Devise.friendly_token[0, TOKEN_LENGTH]
          target = main_app.url_for(pp.merge(crossdomain: token,
                                             host: site_for_crossdomain_devise.env_aware_domain,
                                             site: current_site.slug))

          session[SESSION_KEY] = {
            type: "slave",
            path_parameters: pp,
            source_host: request.host,
            token: token,
            timestamp: Time.current,
          }

          redirect_to target, allow_other_host: true
        end
      end

      def handle_crossdomain_devise_on_master
        Rails.logger.debug "#{request.host} - handle_crossdomain_devise_on_master"

        set_crossdomain_master_session_from_params

        if user_signed_in?
          handle_crossdomain_devise_on_master_when_signed_in
        else
          cleanup_crossdomain_master_url_params
        end
      end

      def set_crossdomain_master_session_from_params
        Rails.logger.debug "#{request.host} - set_crossdomain_master_session_from_params"

        return if params[:crossdomain].blank? || params[:crossdomain].length != TOKEN_LENGTH
        return if params[:site].blank?

        source_site = Folio::Site.find_by_slug(params[:site])
        return if source_site.nil?

        Rails.logger.debug "#{request.host} - set_crossdomain_master_session_from_params - setting session"

        session[SESSION_KEY] = {
          path_parameters: request.path_parameters,
          source_site_id: source_site.id,
          token: params[:crossdomain],
          type: "master",
        }
      end

      def handle_crossdomain_devise_on_master_when_signed_in
        Rails.logger.debug "#{request.host} - handle_crossdomain_devise_on_master_when_signed_in"

        return unless session[SESSION_KEY]
        return unless session[SESSION_KEY][:type] == "master"
        return unless session[SESSION_KEY][:path_parameters]
        return unless session[SESSION_KEY][:source_site_id]
        return unless session[SESSION_KEY][:crossdomain]

        source_site = Folio::Site.find_by_id(session[SESSION_KEY][:source_site_id])
        return unless source_site

        current_user.set_crossdomain_data!

        target = main_app.url_for(session[SESSION_KEY][:path_parameters].merge(crossdomain: session[SESSION_KEY][:crossdomain],
                                                                               crossdomain_user: current_user.crossdomain_devise_token,
                                                                               host: source_site.env_aware_domain))

        session.delete(SESSION_KEY)

        Rails.logger.debug "#{request.host} - handle_crossdomain_devise_on_master_when_signed_in - target #{target}"

        redirect_to target, allow_other_host: true

        return true
      end

      def cleanup_crossdomain_master_url_params
        Rails.logger.debug "#{request.host} - cleanup_crossdomain_master_url_params"
        return if params[:crossdomain].blank? && params[:site].blank?
        Rails.logger.debug "#{request.host} - cleanup_crossdomain_master_url_params - redirect to #{request.path}"
        redirect_to request.path
      end

      def site_for_crossdomain_devise
        @site_for_crossdomain_devise ||= Folio.site_for_crossdomain_devise
      end

      def user_to_sign_in_on_slave
        Rails.logger.debug "#{request.host} - user_to_sign_in_on_slave - params: #{params.to_json}"

        has_valid_devise_token = params[:crossdomain] &&
                                 params[:crossdomain] == session[SESSION_KEY][:crossdomain] &&
                                 session[SESSION_KEY][:timestamp] > TIMESTAMP_THRESHOLD.ago
        return unless has_valid_devise_token

        has_valid_user_token = params[:crossdomain_user] &&
                               params[:crossdomain_user].length == TOKEN_LENGTH
        return unless has_valid_user_token

        Folio::User.where("crossdomain_devise_set_at > ?", TIMESTAMP_THRESHOLD.ago)
                   .find_by(crossdomain_devise_token: params[:crossdomain_user])
      end

      def sign_in_user_from_crossdomain!(user)
        set_flash_message!(:notice, :signed_in)
        sign_in(:user, user)
        respond_with user, location: after_sign_in_path_for(user)
      end
  end

  module DeviseControllerConcern
    extend ActiveSupport::Concern

    include ::Folio::Devise::Crossdomain::ApplicationControllerConcern

    protected
      # override devise signed in check - redirect to source site if needed
      def require_no_authentication
        Rails.logger.debug "#{request.host} - require_no_authentication - user_signed_in? #{user_signed_in?}"

        if user_signed_in? && site_for_crossdomain_devise
          if current_site == site_for_crossdomain_devise
            Rails.logger.debug "#{request.host} - require_no_authentication - master"
            if handle_crossdomain_devise_on_master
              Rails.logger.debug "#{request.host} - require_no_authentication - master - handle_crossdomain_devise_on_master true"
              return
            end
          else
            Rails.logger.debug "#{request.host} - require_no_authentication - slave - redirect to after_sign_in_path_for"
            redirect_to after_sign_in_path_for(current_user)
          end
        end

        super
      end
  end

  module Model
    extend ActiveSupport::Concern

    def set_crossdomain_data!
      update_columns(crossdomain_devise_token: Devise.friendly_token[0, TOKEN_LENGTH],
                     crossdomain_devise_set_at: Time.current)
    end
  end
end
