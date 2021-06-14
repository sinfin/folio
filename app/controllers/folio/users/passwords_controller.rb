# frozen_string_literal: true

class Folio::Users::PasswordsController < Devise::PasswordsController
  include Folio::Users::DeviseControllerBase

  skip_before_action :require_no_authentication, only: %i[edit]
  before_action :sign_out_before_entering, only: %i[edit]

  private
    def sign_out_before_entering
      sign_out(current_user) if current_user
    end
end
