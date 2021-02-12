# frozen_string_literal: true

if Rails.application.config.folio_users
  require "omniauth"

  Rails.application.config.middleware.use OmniAuth::Builder do
    Rails.application.config.folio_users_omniauth_providers.each do |provider|
      if ENV["OMNIAUTH_#{provider.to_s.upcase}_CLIENT_ID"].present?
        provider provider,
                 ENV["OMNIAUTH_#{provider.to_s.upcase}_CLIENT_ID"],
                 ENV["OMNIAUTH_#{provider.to_s.upcase}_CLIENT_SECRET"]
      end
    end
  end
end
