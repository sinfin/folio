# frozen_string_literal: true

module Folio
  module Mcp
    class Railtie < ::Rails::Railtie
      # Add MCP pack paths after user initializers have run
      # This ensures config.enabled = true has been processed
      initializer "folio_mcp.add_autoload_paths", after: :load_config_initializers do |app|
        next unless Folio.pack_enabled?(:mcp)

        pack_root = File.expand_path("../../../..", __dir__)

        # Add autoload paths for MCP pack
        %w[
          app/models
          app/models/concerns
          app/components
          app/components/concerns
          app/controllers
          app/controllers/concerns
          app/helpers
          app/jobs
          app/lib
          app/mailers
        ].each do |subdir|
          path = File.join(pack_root, subdir)
          if File.exist?(path)
            app.config.autoload_paths << path
            app.config.eager_load_paths << path
            ActiveSupport::Dependencies.autoload_paths << path if defined?(ActiveSupport::Dependencies.autoload_paths)
          end
        end

        # Add views path
        views_path = File.join(pack_root, "app/views")
        app.config.paths["app/views"] << views_path if File.exist?(views_path)

        # Add migrations path
        migrate_path = File.join(pack_root, "db/migrate")
        app.config.paths["db/migrate"] << migrate_path if File.exist?(migrate_path)

        # Add locales
        locales_path = File.join(pack_root, "config/locales")
        if File.exist?(locales_path)
          app.config.i18n.load_path += Dir[File.join(locales_path, "**", "*.yml")]
        end

        # Add asset paths for components
        components_path = File.join(pack_root, "app/components")
        app.config.assets.paths << components_path if File.exist?(components_path)
      end
    end
  end
end
