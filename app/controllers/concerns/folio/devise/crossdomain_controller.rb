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

      result = Folio::Devise::CrossdomainHandler.new(request:,
                                                     session:,
                                                     params:,
                                                     current_site:,
                                                     current_resource: safe_resource_name == :account ? current_account : current_user,
                                                     controller_name:,
                                                     resource_name: safe_resource_name,
                                                     action_name:,
                                                     devise_controller: try(:devise_controller?),
                                                     master_site: Folio.site_for_crossdomain_devise,
                                                     resource_class: safe_resource_name == :account ? Folio::Account : Folio::User).handle_before_action!

      case result.action
      when :sign_in_on_target_site
        redirect_to main_app.send("new_#{result.resource_name}_session_url", result.params),
                    allow_other_host: true

      when :redirect_to_sessions_new
        redirect_to main_app.send("new_#{result.resource_name}_session_path")

      when :redirect_to_master_invitations_new
        redirect_to main_app.send("new_#{result.resource_name}_invititation_url", result.params),
                    allow_other_host: true

      when :redirect_to_master_sessions_new
        redirect_to main_app.send("new_#{result.resource_name}_session_url", result.params),
                    allow_other_host: true

      when :sign_in
        sign_in(result.resource_name, result.resource)
        redirect_to after_sign_in_path_for(result.resource)

      else
        # noop
      end

      @devise_crossdomain_result = result
    end
end
