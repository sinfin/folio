# frozen_string_literal: true

class Folio::Users::RegistrationsController < Devise::RegistrationsController
  private
    def sign_up_params
      params.require(:user).permit(:first_name, :last_name).to_h.merge(super)
    end
end
