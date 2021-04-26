# frozen_string_literal: true

module Folio::Users::DeviseUserPaths
  def after_sign_in_path_for(_resource)
    stored_location_for(:user) ||
    main_app.send(Rails.application.config.folio_users_after_sign_in_path)
  end

  def after_sign_out_path_for(_resource)
    main_app.send(Rails.application.config.folio_users_after_sign_out_path)
  end

  def after_sign_up_path_for(_resource)
    stored_location_for(:user) ||
    main_app.send(Rails.application.config.folio_users_after_sign_up_path)
  end

  def after_accept_path_for(_resource)
    stored_location_for(:user) ||
    main_app.send(Rails.application.config.folio_users_after_accept_path)
  end

  def signed_in_root_path(_resource)
    main_app.send(Rails.application.config.folio_users_signed_in_root_path)
  end
end
