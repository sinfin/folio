# frozen_string_literal: true

module Folio
  class Engine < ::Rails::Engine
    isolate_namespace Folio

    config.to_prepare do
      Devise::SessionsController.layout 'folio/console/devise'
      Devise::ConfirmationsController.layout 'folio/console/devise'
      Devise::UnlocksController.layout 'folio/console/devise'
      Devise::PasswordsController.layout 'folio/console/devise'

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
    config.folio_pages_translations = false
    config.folio_pages_ancestry = false
    config.folio_console_locale = :cs
    config.folio_console_dashboard_redirect = :console_pages_path
    config.folio_console_sidebar_prepended_link_class_names = []
    config.folio_console_sidebar_appended_link_class_names = []
    config.folio_console_sidebar_runner_up_link_class_names = []

    initializer :append_migrations do |app|
      unless app.root.to_s.match? root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end
  end
end
