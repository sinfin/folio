# frozen_string_literal: true

class Folio::Users::PasswordsController < Devise::PasswordsController
  def after_resetting_password_path_for(_resource)
    root_path
  end
end
