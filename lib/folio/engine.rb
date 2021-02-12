# frozen_string_literal: true

module Folio
  class Engine < ::Rails::Engine
    isolate_namespace Folio

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
    end

    config.assets.paths << self.root.join("app/cells")
    config.assets.paths << self.root.join("vendor/assets/javascripts")
    config.assets.paths << self.root.join("vendor/assets/bower_components")
    config.assets.precompile += %w[
      folio/console/base.css
      folio/console/base.js
      folio/console/react/main.js
      folio/console/react/main.css
    ]

    config.folio_dragonfly_keep_png = true
    config.folio_public_page_title_reversed = false
    config.folio_using_traco = false
    config.folio_pages_audited = false
    config.folio_pages_translations = false
    config.folio_pages_ancestry = false
    config.folio_users = false
    config.folio_users_confirmable = true
    config.folio_users_omniauth_providers = %i[facebook google twitter]
    config.folio_pages_perex_richtext = false
    config.folio_console_locale = :cs
    config.folio_console_dashboard_redirect = :console_pages_path
    config.folio_console_sidebar_link_class_names = nil
    config.folio_console_sidebar_prepended_link_class_names = []
    config.folio_console_sidebar_appended_link_class_names = []
    config.folio_console_sidebar_runner_up_link_class_names = []
    config.folio_console_sidebar_skip_link_class_names = []
    config.folio_server_names = []
    config.folio_image_spacer_background_fallback = nil
    config.folio_show_transportable_frontend = false

    initializer :append_migrations do |app|
      unless app.root.to_s.include? root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer :add_watchable_cell_i18n_files do |app|
      dirs = {
        Folio::Engine.root.join("app/cells").to_s => [".yml"],
        Rails.root.join("app/cells").to_s => [".yml"]
      }
      cells_i18n_reloader = app.config.file_watcher.new([], dirs) do
        I18n.reload!
      end
      app.reloaders << cells_i18n_reloader

      ActiveSupport::Reloader.to_prepare do
        cells_i18n_reloader.execute_if_updated
      end
    end
  end
end
