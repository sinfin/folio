# frozen_string_literal: true

class Folio::Devise::Omniauth::FormsCell < Folio::Devise::ApplicationCell
  STIMULUS_CONTROLLER_NAME = "f-devise-omniauth-forms-trigger"

  def show
    render if ::Rails.application.config.folio_users_omniauth_providers.present?
  end

  def omniauth_sign_in_form(key, &block)
    url = controller.main_app.send("user_#{key}_omniauth_authorize_path")
    simple_form_for "", url:, &block
  end
end
