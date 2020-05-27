# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require 'folio'

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    I18n.available_locales = [:cs, :en]
    I18n.default_locale = :cs

    # Custom error pages
    config.exceptions_app = self.routes

    config.folio_console_locale = I18n.default_locale
    config.time_zone = 'Prague'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    Rails.autoloaders.main.ignore("#{::Folio::Engine.root}/app/lib/folio/console/simple_form_components")
    Rails.autoloaders.main.ignore("#{::Folio::Engine.root}/app/lib/folio/console/simple_form_inputs")

    overrides = [
      Folio::Engine.root.join('app/overrides').to_s,
      Rails.root.join('app/overrides').to_s,
    ]

    overrides.each { |override| Rails.autoloaders.main.ignore(override) }

    config.to_prepare do
      overrides.each do |override|
        Dir.glob("#{override}/**/*_override.rb").each do |file|
          load file
        end
      end

      Dir.glob("#{::Folio::Engine.root}/app/lib/folio/console/simple_form*/**.rb").each do |sf|
        load sf
      end
    end
  end
end
