# frozen_string_literal: true

module Folio
  module Omniauth
    def self.table_name_prefix
      "folio_omniauth_"
    end

    def self.setup_providers(provider_keys)
      Rails.application.config.middleware.use OmniAuth::Builder do
        provider_keys.each do |provider_key|
           Folio::Omniauth.check_env_keys(provider_key)

           if provider_key == :apple && ENV["OMNIAUTH_APPLE_SERVICE_BUNDLE_ID"]
             provider :apple,
                      ENV["OMNIAUTH_APPLE_SERVICE_BUNDLE_ID"],
                      "",
                      {
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

    def self.check_env_keys(provider_key)
      required_keys = if provider_key == :apple
        # see https://github.com/nhosoya/omniauth-apple#look-out-for-the-values-you-need-for-your-config
        ["OMNIAUTH_APPLE_SERVICE_BUNDLE_ID", # client_id, is in the top-right of your ServicesId config (aka Identifier), it looks like: com.example
          "OMNIAUTH_APPLE_APP_ID_PREFIX", # team_id, is in the top-right of your AppId config (aka App ID Prefix), it looks like: H000000B
          "OMNIAUTH_APPLE_KEY_ID", # key_id, is on the left side of your Key Details page, it looks like: XYZ000000
          "OMNIAUTH_APPLE_P8_FILE_CONTENT_WITH_EXTRA_NEWLINE"] #  is the content of the .p8 file you got from Apple, with an extra newline at the end
      else
        ["OMNIAUTH_#{provider_key.to_s.upcase}_CLIENT_ID",
         "OMNIAUTH_#{provider_key.to_s.upcase}_CLIENT_SECRET"]
      end

      raise ":#{provider_key} Omniauth requires ENV variablaes #{required_keys} !" if required_keys.any? { |key| ENV[key].blank? || ENV[key] == "find-me-in-vault" }
    end
  end
end
