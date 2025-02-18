# frozen_string_literal: true

class Folio::Devise::Omniauth::AuthenticationsController < Folio::ApplicationController
  include Folio::Users::DeviseControllerBase

  before_action :authenticate_user!

  def destroy
    provider = params.require(:provider)

    Folio::Current.user.authentications
                       .where(provider:)
                       .destroy_all

    msg = t(".success",
            provider: Folio::Omniauth::Authentication.human_provider(provider))

    redirect_back fallback_location:,
                  flash: { success: msg }
  end

  def fallback_location
    signed_in_root_path(Folio::Current.user)
  end
end
