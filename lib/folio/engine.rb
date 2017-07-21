# frozen_string_literal: true

module Folio
  class Engine < ::Rails::Engine
    isolate_namespace Folio

    initializer 'errors', before: :load_config_initializers do |app|

      Rails.application.config.exceptions_app = self.routes
    end
  end
end
