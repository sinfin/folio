# frozen_string_literal: true

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)
require "folio"

Folio.enabled_packs = [:ai] if Rails.env.development? || Rails.env.test?

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.folio_leads_from_component_class_name = "Folio::Leads::FormComponent"
    config.folio_newsletter_subscriptions = true
    config.folio_site_default_test_factory = :dummy_site

    config.folio_tiptap_use_for_pages = true

    I18n.available_locales = [:cs, :en]
    I18n.default_locale = :cs

    # Load Folio gem locale files
    config.i18n.load_path += Dir[Folio::Engine.root.join("config", "locales", "**", "*.yml")]

    # Custom error pages
    config.exceptions_app = self.routes

    config.action_mailer.deliver_later_queue_name = "mailers"

    config.folio_console_locale = I18n.default_locale
    config.time_zone = "Prague"

    packs_root = root.join("packs")
    if packs_root.exist?
      Dir.glob(packs_root.join("*")).each do |pack_path|
        pack_root = Pathname.new(pack_path)
        next unless pack_root.directory?

        pack_name = pack_root.basename.to_s

        %w[app/models app/models/concerns app/components app/controllers app/helpers].each do |subdir|
          path = pack_root.join(subdir)
          next unless path.exist?

          config.autoload_paths << path
          config.eager_load_paths << path
        end

        migrate_path = pack_root.join("db/migrate")
        config.paths["db/migrate"] << migrate_path if migrate_path.exist?

        railtie_path = pack_root.join("lib/dummy/#{pack_name}.rb")
        require railtie_path if railtie_path.exist?
      end
    end

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
      g.test_framework :test_unit, fixture: false
    end

    overrides = [
      Folio::Engine.root.join("app/overrides").to_s,
      Rails.root.join("app/overrides").to_s,
    ]

    overrides.each { |override| Rails.autoloaders.main.ignore(override) }

    config.to_prepare do
      overrides.each do |override|
        Dir.glob("#{override}/**/*_override.rb").each do |file|
          load file
        end
      end
    end
  end
end
