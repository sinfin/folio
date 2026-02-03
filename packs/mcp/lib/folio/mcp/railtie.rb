# frozen_string_literal: true

module Folio
  module Mcp
    class Railtie < ::Rails::Railtie
      # Add generators path to load path so rails g folio:mcp:install works
      generators do
        require_relative "../../generators/folio/mcp/install_generator"
      end

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
