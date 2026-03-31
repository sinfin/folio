# frozen_string_literal: true

module Folio
  module RecordCache
    class Railtie < ::Rails::Railtie
      initializer "folio_record_cache.identity_cache" do
        IdentityCache.cache_backend = Rails.cache
      end

      config.to_prepare do
        Folio::Site.include(Folio::RecordCache::SiteConcern)
        Folio::Page.include(Folio::RecordCache::PageConcern) unless Rails.application.config.folio_using_traco
        Folio::File.include(Folio::RecordCache::FileConcern)
        Folio::Menu.include(Folio::RecordCache::MenuConcern)
      end
    end
  end
end
