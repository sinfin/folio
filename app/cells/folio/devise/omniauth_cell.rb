# frozen_string_literal: true

class Folio::Devise::OmniauthCell < Folio::Devise::ApplicationCell
  def show
    render if omniauth_providers_with_keys_present.present?
  end

  def button_data(provider)
    stimulus_controller(Folio::Devise::Omniauth::FormsCell::STIMULUS_CONTROLLER_NAME,
                        values: { provider: },
                        action: "click")
  end

  def omniauth_providers_with_keys_present
    @omniauth_providers_with_keys_present ||= ::Rails.application.config.folio_users_omniauth_providers.filter_map do |key|
      if key == :apple
        key if ENV["OMNIAUTH_APPLE_KEY_ID"].present?
      else
        key if ENV["OMNIAUTH_#{key.to_s.upcase}_CLIENT_ID"].present?
      end
    end
  end
end
