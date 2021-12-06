# frozen_string_literal: true

class Folio::Accounts::SessionsController < Devise::SessionsController
  layout "folio/console/devise"

  def after_sign_in_path_for(_resource)
    stored_location_for(:account).presence || console_root_path
  end

  def after_sign_out_path_for(_resource)
    new_account_session_path
  rescue ActionController::UrlGenerationError
    main_app.new_account_session_path
  end
end
