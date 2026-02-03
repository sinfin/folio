# frozen_string_literal: true

module Folio
  module Mcp
    class Railtie < ::Rails::Railtie
      config.to_prepare do
        Folio::User.include(Folio::HasMcpToken)
      end

      # Add generators path to load path so rails g folio:mcp:install works
      generators do
        require_relative "../../generators/folio/mcp/install_generator"
      end

      initializer "append_folio_mcp_autoload_paths" do |app|
        # Add app/lib for MCP tools, serializers, etc.
        app.config.autoload_paths += [::Rails.root.join("app/lib")]
        app.config.eager_load_paths += [::Rails.root.join("app/lib")]
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
