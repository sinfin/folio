# frozen_string_literal: true

require Folio::Engine.root.join("app/models/folio/omniauth") # to load Folio::Omniauth namespace

if Rails.application.config.folio_users && Rails.application.config.folio_users_omniauth_providers.present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    Rails.application.config.folio_users_omniauth_providers.each do |provider_key|
      if ENV["OMNIAUTH_#{provider_key.to_s.upcase}_CLIENT_ID"].present?
        if provider_key == :twitter2
          provider provider_key,
                   ENV["OMNIAUTH_#{provider_key.to_s.upcase}_CLIENT_ID"],
                   ENV["OMNIAUTH_#{provider_key.to_s.upcase}_CLIENT_SECRET"],
                   scope: "tweet.read users.read"
        else
          provider provider_key,
                   ENV["OMNIAUTH_#{provider_key.to_s.upcase}_CLIENT_ID"],
                   ENV["OMNIAUTH_#{provider_key.to_s.upcase}_CLIENT_SECRET"]
        end
      end
    end
  end
end
