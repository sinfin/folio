# frozen_string_literal: true

module Folio
  class Engine < ::Rails::Engine
    isolate_namespace Folio

    config.to_prepare do
      [
        Devise::ConfirmationsController,
        Devise::OmniauthCallbacksController,
        Devise::PasswordsController,
        Devise::RegistrationsController,
        Devise::SessionsController,
        Devise::UnlocksController,

        Devise::InvitationsController,
        DeviseInvitable::RegistrationsController,
      ].each do |controller|
        controller.send(:include, Folio::DeviseExtension)
      end

      Dir.glob(Rails.root + 'app/decorators/**/*_decorator*.rb').each do |c|
        require_dependency(c)
      end
    end

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
    end

    config.autoload_paths << self.root.join('lib')
    config.eager_load_paths << self.root.join('lib')
    config.assets.paths << self.root.join('app/cells')
    config.assets.paths << self.root.join('vendor/assets/javascripts')
    config.assets.paths << self.root.join('vendor/assets/bower_components')
    config.assets.precompile += %w[
      folio/console/base.css
      folio/console/base.js
      folio/console/react/main.js
      folio/console/react/main.css
    ]

    config.folio_dragonfly_keep_png = false
    config.folio_public_page_title_reversed = false
    config.folio_using_traco = false
    config.folio_pages_audited = false
    config.folio_pages_translations = false
    config.folio_pages_ancestry = false
    config.folio_routes_localized = true
    config.folio_console_locale = :cs
    config.folio_console_dashboard_redirect = :console_pages_path
    config.folio_console_sidebar_prepended_link_class_names = []
    config.folio_console_sidebar_appended_link_class_names = []
    config.folio_console_sidebar_runner_up_link_class_names = []
    config.folio_server_names = []

    config.folio_cookie_consent_configuration = {
      enabled: true,
      cookies: {
        necessary: [
          :cc_cookie,
          :session_id,
          :s_for_log,
          :u_for_log,
        ],
        analytics: [
          :_ga,
          :_gid,
          :_ga_container_id,
          :_gac_gb_container_id,
        ]
      }
    }

    initializer :append_migrations do |app|
      unless app.root.to_s.include? root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer :add_watchable_cell_i18n_files do |app|
      dirs = {
        Folio::Engine.root.join('app/cells').to_s => ['.yml'],
        Rails.root.join('app/cells').to_s => ['.yml']
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
