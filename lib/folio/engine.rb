# frozen_string_literal: true

module Folio
  class Engine < ::Rails::Engine
    isolate_namespace Folio

    initializer 'errors', before: :load_config_initializers do |app|

      Rails.application.config.exceptions_app = self.routes
    end

    config.autoload_paths << self.root.join('lib')
    config.eager_load_paths << self.root.join('lib')
    config.assets.paths << self.root.join('app/cells')

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end
  end
end
