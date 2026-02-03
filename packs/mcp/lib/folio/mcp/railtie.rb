# frozen_string_literal: true

module Folio
  module Mcp
    class Railtie < ::Rails::Railtie
      initializer "folio_mcp.routes", before: :add_routing_paths do |app|
        app.routes.prepend do
          # MCP API endpoint (controller handles disabled state)
          namespace :folio do
            namespace :api do
              post "mcp", to: "mcp#handle"
            end
          end
        end
      end
    end
  end
end
