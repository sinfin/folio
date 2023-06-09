# frozen_string_literal: true

module Rack
  module Folio
    class MaintenanceMiddleware
      WHITELIST_REGEX = /\A\/(console|sidekiq|assets|accounts|api\/s3|app\/status\.json)/

      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)

        if request.path.match?(WHITELIST_REGEX)
          @app.call(env)
        else
          render_maintenance_html
        end
      end

      def render_maintenance_html
        [503, { "Content-Type" => "text/html" }, [self.class.maintenance_html]]
      end

      def self.maintenance_html
        @maintenance_html ||= ::File.read(::Rails.root.join("public/maintenance.html"))
      end
    end
  end
end
