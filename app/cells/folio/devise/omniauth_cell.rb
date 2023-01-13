# frozen_string_literal: true

class Folio::Devise::OmniauthCell < Folio::Devise::ApplicationCell
  def show
    render if ::Rails.application.config.folio_users_omniauth_providers.present?
  end

  def url_for_key(key)
    url = controller.main_app.send("user_#{key}_omniauth_authorize_path")
    controller.folio.users_comeback_path(to: url)
  end
end
