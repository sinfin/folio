# frozen_string_literal: true

class Folio::Devise::Omniauth::AuthenticationsController < Folio::ApplicationController
  include Folio::Users::DeviseUserPaths

  before_action :authenticate_user!

  def destroy
    provider = params.require(:provider)

    current_user.authentications
                .where(provider: provider)
                .destroy_all

    msg = t(".success",
            provider: Folio::Omniauth::Authentication.human_provider(provider))

    redirect_back fallback_location: fallback_location,
                  flash: { success: msg }
  end

  def fallback_location
    signed_in_root_path(current_user)
  end
end
