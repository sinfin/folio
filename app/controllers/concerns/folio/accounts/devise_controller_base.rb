# frozen_string_literal: true

module Folio::Accounts::DeviseControllerBase
  extend ActiveSupport::Concern
  include Folio::Devise::CrossdomainController

  included do
    layout "folio/console/devise"
  end

  def after_sign_in_path_for(_resource)
    stored_location_for(:account).presence ||
    console_root_path
  end

  def after_sign_out_path_for(_resource)
    folio.new_account_session_path
  rescue NoMethodError
    main_app.new_account_session_path
  end

  def after_sign_up_path_for(_resource)
    stored_location_for(:account).presence ||
    console_root_path
  end

  def after_accept_path_for(_resource)
    stored_location_for(:account).presence ||
    console_root_path
  end

  def signed_in_root_path(_resource)
    console_root_path
  end

  protected
    # override devise signed in check - redirect to source site if needed
    def require_no_authentication
      result = handle_crossdomain_devise
      super if result && result.action == :noop
    end
end
