# frozen_string_literal: true

module Rack
  module Folio
    class UrlRedirectsMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        if Rails.application.config.folio_url_redirects_enabled
          if result = ::Folio::UrlRedirect.handle_env(env)
            return result
          end
        end

        @app.call(env)
      end
    end
  end
end
