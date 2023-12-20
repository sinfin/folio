# frozen_string_literal: true

module Folio::Devise::CrossdomainController
  extend ActiveSupport::Concern

  included do
    before_action :handle_crossdomain_devise
  end

  private
    def handle_crossdomain_devise
      return unless Rails.application.config.folio_crossdomain_devise && !Rails.env.test?
      return @devise_crossdomain_result if @devise_crossdomain_result

      safe_resource_name = (defined?(resource_name) ? resource_name : nil) || :user

      @devise_crossdomain_handler = Folio::Devise::CrossdomainHandler.new(request:,
                                                                          session:,
                                                                          params:,
                                                                          current_site:,
                                                                          current_resource: current_user,
                                                                          controller_name:,
                                                                          resource_name: safe_resource_name,
                                                                          action_name:,
                                                                          devise_controller: try(:devise_controller?),
                                                                          master_site: Folio.site_for_crossdomain_devise,
                                                                          resource_class: Folio::User)

      result = @devise_crossdomain_handler.handle_before_action!

      case result.action
      when :sign_in_on_target_site
        flash.discard
        redirect_to main_app.send("new_#{result.resource_name}_session_url", result.params),
                    allow_other_host: true

      when :redirect_to_sessions_new
        redirect_to main_app.send("new_#{result.resource_name}_session_path")

      when :redirect_to_master_invitations_new
        redirect_to main_app.send("new_#{result.resource_name}_invitation_url", result.params),
                    allow_other_host: true

      when :redirect_to_master_sessions_new
        redirect_to main_app.send("new_#{result.resource_name}_session_url", result.params),
                    allow_other_host: true

      when :sign_in
        flash.discard
        sign_in(result.resource_name, result.resource)
        redirect_to after_sign_in_path_for(result.resource),
                    flash: { notice: t("devise.sessions.signed_in") }

      else
        # noop - aka proceed with original action
      end

      @devise_crossdomain_result = result
    end

    def authenticate_user!(*args)
      if Rails.application.config.folio_crossdomain_devise &&
         current_user.nil? &&
         current_site != Folio.site_for_crossdomain_devise
        handle_crossdomain_devise

        result = @devise_crossdomain_handler.authenticate_user_on_slave_site!
        store_location_for(:user, request.fullpath)

        redirect_to main_app.send("new_#{result.resource_name}_session_url", result.params),
                    allow_other_host: true
      else
        super
      end
    end
end
