# frozen_string_literal: true

class Folio::Users::MagicLinksController < Devise::MagicLinksController
  def show
    self.resource, _data = Devise::Passwordless::SignedGlobalIDTokenizer.decode(params[:token], resource_class)

    if resource
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      redirect_to after_sign_in_path_for(resource)
    else
      redirect_to new_session_path(resource_name), alert: I18n.t("devise.failure.magic_link_invalid")
    end
  rescue Devise::Passwordless::ExpiredTokenError, Devise::Passwordless::InvalidTokenError
    redirect_to new_session_path(resource_name), alert: I18n.t("devise.failure.magic_link_invalid")
  end
end
