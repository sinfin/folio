# frozen_string_literal: true

require "rails/generators/active_record/migration"

require Folio::Engine.root.join("lib/generators/folio/generator_base")

module Folio
  module Mcp
    class InstallGenerator < Rails::Generators::Base
      include Folio::GeneratorBase
      include ActiveRecord::Generators::Migration

      source_root ::File.expand_path("templates", __dir__)

      desc "Install Folio MCP server"

      def create_mcp
        template "mcp.rb.tt", "packs/mcp/lib/#{application_namespace_path}/mcp.rb"
      end

      def create_railtie
        template "railtie.rb.tt", "packs/mcp/lib/#{application_namespace_path}/mcp/railtie.rb"
      end

      def create_cursor_config_sample
        template "mcp.json.tt", ".cursor/mcp.json.sample"
      end

      def create_mcp_migration
        migration_template "migration.rb.tt",
                           "db/migrate/add_mcp_to_folio_users.rb"
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
        say "2. Edit packs/mcp/lib/#{application_namespace_path}/mcp/railtie.rb to set up your resources.", :cyan
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
    end
  end
end
