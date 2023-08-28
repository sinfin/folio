# frozen_string_literal: true

class Folio::Devise::Omniauth::Authentications::ListCell < Folio::Devise::ApplicationCell
  def show
    render if model.present? && ::Rails.application.config.folio_users_omniauth_providers.present?
  end

  def authentications
    @authentications ||= model.authentications.to_a
  end

  def authentication_for(provider)
    authentications.find { |a| a.provider == provider.to_s }
  end

  def url_for_key(key)
    url = controller.main_app.send("user_#{key}_omniauth_authorize_path")
    controller.folio.users_comeback_path(to: url)
  end

  def can_remove_auth?
    model.email.present? || authentications.group_by(&:provider).size > 1
  end

  def unlink_url_for(provider)
    controller.folio.devise_omniauth_authentication_path(provider:)
  end

  def button_data(provider)
    stimulus_controller(Folio::Devise::Omniauth::FormsCell::STIMULUS_CONTROLLER_NAME,
                        values: { provider: },
                        action: "click")
  end
end
