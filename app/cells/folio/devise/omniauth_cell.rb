# frozen_string_literal: true

class Folio::Devise::OmniauthCell < Folio::Devise::ApplicationCell
  def show
    render if ::Rails.application.config.folio_users_omniauth_providers.present?
  end

  def button_data(provider)
    stimulus_controller(Folio::Devise::Omniauth::FormsCell::STIMULUS_CONTROLLER_NAME,
                        values: { provider: },
                        action: "click")
  end
end
