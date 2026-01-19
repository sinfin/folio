# frozen_string_literal: true

module Folio
  module Cache
    class Railtie < ::Rails::Railtie
      config.to_prepare do
        Folio::ApplicationRecord.include(Folio::Cache::ModelConcern)
      end
    end
  end
end
