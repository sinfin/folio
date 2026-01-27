# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Folio
  module Mcp
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Install Folio MCP server"

      def create_initializer
        template "folio_mcp.rb.tt", "config/initializers/folio_mcp.rb"
      end

      def create_cursor_config_sample
        template "mcp.json.tt", ".cursor/mcp.json.sample"
      end

      def create_migration
        migration_template "migration.rb.tt",
                           "db/migrate/add_mcp_to_folio_users.rb",
                           migration_version: migration_version
      end

      def add_route
        route_content = <<~ROUTE

          # MCP API endpoint (only if enabled)
          if Folio::Mcp.enabled?
            scope :folio, as: :folio do
              namespace :api do
                post "mcp", to: "mcp#handle"
              end
            end
          end
        ROUTE

        inject_into_file "config/routes.rb",
                         route_content,
                         after: "Rails.application.routes.draw do"
      end

      def show_instructions
        say ""
        say "=" * 60
        say "Folio MCP Server installed!", :green
        say "=" * 60
        say ""
        say "Next steps:", :yellow
        say ""
        say "1. Run migrations:"
        say "   rails db:migrate", :cyan
        say ""
        say "2. Edit config/initializers/folio_mcp.rb to configure resources"
        say ""
        say "3. Generate API token for a user:"
        say "   rails folio:mcp:generate_token[admin@example.com]", :cyan
        say ""
        say "4. Set up Cursor:"
        say "   cp .cursor/mcp.json.sample .cursor/mcp.json", :cyan
        say "   Then add your token to .cursor/mcp.json"
        say ""
        say "5. Test the connection:"
        say "   curl -X POST http://localhost:3000/folio/api/mcp \\", :cyan
        say "     -H 'Authorization: Bearer YOUR_TOKEN' \\", :cyan
        say "     -H 'Content-Type: application/json' \\", :cyan
        say "     -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"ping\"}'", :cyan
        say ""
      end

      private
        def migration_version
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end

        def application_name
          Rails.application.class.module_parent_name.underscore.dasherize
        end
    end
  end
end
