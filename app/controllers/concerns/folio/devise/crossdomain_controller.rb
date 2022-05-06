# frozen_string_literal: true

module Folio::Devise::CrossdomainController
  extend ActiveSupport::Concern

  included do
    before_action :handle_crossdomain_devise
  end

  private
    def handle_crossdomain_devise
      return @devise_crossdomain_result if @devise_crossdomain_result

      result = Folio::Devise::Crossdomain.new(request:,
                                              session:,
                                              current_site:,
                                              current_user:,
                                              controller_name:,
                                              action_name:,
                                              devise_controller: try(:devise_controller?)).handle_before_action!

      case result.action
      when :noop
        return result
      when :sign_in_on_target_site
        redirect_to main_app.new_user_session_path(result.params), allow_other_host: true
      when :redirect_to_sessions_new
        redirect_to main_app.new_user_session_path
      when :redirect_to_master_invitations_new
        redirect_to main_app.new_user_invititation_path(result.params), allow_other_host: true
      when :redirect_to_master_sessions_new
        redirect_to main_app.new_user_session_path(result.params), allow_other_host: true
      when :sign_in
        sign_in(:user, target.user)
        redirect_to after_sign_in_path_for(target.user)
      end

      @devise_crossdomain_result = result
    end

  protected
    # override devise signed in check - redirect to source site if needed
    def require_no_authentication
      result = handle_crossdomain_devise
      super if result.action == :noop
    end
end
