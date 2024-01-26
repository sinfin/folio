# frozen_string_literal: true

module Folio
  module Omniauth
    def self.table_name_prefix
      "folio_omniauth_"
    end

    def self.setup_providers(provider_keys)
      return if Rails.env.development? && !defined?(OmniAuth)

      Rails.application.config.middleware.use OmniAuth::Builder do
        provider_keys.each do |provider_key|
           if provider_key == :apple && ENV["OMNIAUTH_APPLE_SERVICE_BUNDLE_ID"]
             provider :apple,
                      ENV["OMNIAUTH_APPLE_SERVICE_BUNDLE_ID"],
                      "",
                      scope: "email name",
                      team_id: ENV["OMNIAUTH_APPLE_APP_ID_PREFIX"],
                      key_id: ENV["OMNIAUTH_APPLE_KEY_ID"],
                      pem: ENV["OMNIAUTH_APPLE_P8_FILE_CONTENT_WITH_EXTRA_NEWLINE"]
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
  end
end
