# frozen_string_literal: true

module Folio
  module Cache
    DEFAULT_EXPIRES_IN = 1.hour

    mattr_accessor :expires_at_for_key, default: nil

    def self.configure(&block)
      if block.arity == 0
        # Block form for temporary configuration (useful in tests)
        previous_expires_at_for_key = expires_at_for_key
        begin
          yield
        ensure
          self.expires_at_for_key = previous_expires_at_for_key
        end
      else
        # Config form for permanent configuration (initializers)
        yield self
      end
    end

    class Railtie < ::Rails::Railtie
      config.to_prepare do
        Folio::Publishable::Basic.include(Folio::Cache::PublishableExtension)
        Folio::Publishable::WithDate.include(Folio::Cache::PublishableWithDateExtension)
        Folio::Publishable::Within.include(Folio::Cache::PublishableWithinExtension)
        Folio::Current.include(Folio::Cache::CurrentConcern)
        Folio::ApplicationRecord.include(Folio::Cache::ModelConcern)
        Folio::ApplicationComponent.include(Folio::Cache::Helper)
      end

      initializer "folio_cache.helpers" do
        ActiveSupport.on_load(:action_view) do
          include Folio::Cache::Helper
        end
      end
    end
  end
end
