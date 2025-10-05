# frozen_string_literal: true

class Folio::Devise::OmniauthCell < Folio::Devise::ApplicationCell
  def show
    render if ::Rails.application.config.folio_users_omniauth_providers.present?
  end

  def button_data(provider)
    controller_name = Folio::Devise::Omniauth::FormsCell::STIMULUS_CONTROLLER_NAME

    {
      "controller" => controller_name,
      "#{controller_name}-provider-value" => provider,
      "action" => "click->#{controller_name}#click"
    }
  end

  def data
    stimulus_controller("f-devise-omniauth")
  end
end
