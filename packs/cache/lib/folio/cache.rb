# frozen_string_literal: true

module Folio
  module Cache
    DEFAULT_EXPIRES_IN = 1.hour

    class Railtie < ::Rails::Railtie
      config.to_prepare do
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
