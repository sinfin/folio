# frozen_string_literal: true

require Folio::Engine.root.join("app/models/folio/omniauth") # to load Folio::Omniauth namespace

if Rails.application.config.folio_users
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
      elsif provider_key == :apple && ENV["APPLE_SERVICE_BUNDLE_ID"]
        provider :apple, ENV["APPLE_SERVICE_BUNDLE_ID"], "", {
          scope: "email name",
          team_id: ENV["APPLE_APP_ID_PREFIX"],
          key_id: ENV["APPLE_KEY_ID"],
          pem: ENV["APPLE_P8_FILE_CONTENT_WITH_EXTRA_NEWLINE"],
        }
      end
    end
  end
end
