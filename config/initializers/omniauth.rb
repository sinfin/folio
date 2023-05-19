# frozen_string_literal: true

require Folio::Engine.root.join("app/models/folio/omniauth") # to load Folio::Omniauth namespace

if Rails.application.config.folio_users
  Rails.application.config.middleware.use OmniAuth::Builder do
    Rails.application.config.folio_users_omniauth_providers.each do |provider_key|
      if provider_key == :apple && ENV["OMNIAUTH_APPLE_SERVICE_BUNDLE_ID"]
        provider :apple, ENV["OMNIAUTH_APPLE_SERVICE_BUNDLE_ID"], "", {
          scope: "email name",
          team_id: ENV["OMNIAUTH_APPLE_APP_ID_PREFIX"],
          key_id: ENV["OMNIAUTH_APPLE_KEY_ID"],
          pem: ENV["OMNIAUTH_APPLE_P8_FILE_CONTENT_WITH_EXTRA_NEWLINE"],
        }
      elsif ENV["OMNIAUTH_#{provider_key.to_s.upcase}_CLIENT_ID"].present?
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
