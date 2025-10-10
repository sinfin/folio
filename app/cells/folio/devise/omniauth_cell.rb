# frozen_string_literal: true

class Folio::Devise::OmniauthCell < Folio::Devise::ApplicationCell
  def show
    render if ::Rails.application.config.folio_users_omniauth_providers.present?
  end

  def button_data(provider)
    controller_name = Folio::Devise::Omniauth::FormsCell::STIMULUS_CONTROLLER_NAME

    stimulus_controller(controller_name, values: { provider: }, action: "click->#{controller_name}#click")
  end

  def data
    stimulus_controller("f-devise-omniauth")
  end

  def disabled_by_default?
    model == 'registrations'
  end
end
