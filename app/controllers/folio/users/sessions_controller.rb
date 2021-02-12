# frozen_string_literal: true

class Folio::Users::SessionsController < Devise::SessionsController
  def after_sign_in_path_for(_resource)
    root_path
  end

  def after_sign_out_path_for(_resource)
    new_user_session_path
  rescue ActionController::UrlGenerationError
    main_app.new_user_session_path
  end
end
