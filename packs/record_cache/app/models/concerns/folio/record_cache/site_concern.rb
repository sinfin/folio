# frozen_string_literal: true

# Identity Cache for +Folio::Site+ (+fetch_by_slug+, +fetch_by_domain+). This layer stacks
# with +Folio::Current.cache_aware_get_site+ (Rails.cache); both can be warm with 0 SQL.
module Folio::RecordCache::SiteConcern
  extend ActiveSupport::Concern
  include Folio::RecordCache::BaseConcern

  included do
    include IdentityCache
    cache_index :slug, unique: true
    cache_index :domain, unique: true
  end

  class_methods do
    def find_or_fetch_by_domain(domain)
      fetch_by_domain(domain)
    end

    def find_or_fetch_by_slug(slug)
      fetch_by_slug(slug)
    end
  end
end
