# frozen_string_literal: true

# Cached slug lookup per site when +folio_using_traco+ is false (single +slug+ column).
# With Traco, localized slug columns are not registered here; use DB-backed +find_or_fetch+ only.
module Folio::RecordCache::PageConcern
  extend ActiveSupport::Concern
  include Folio::RecordCache::BaseConcern

  included do
    include IdentityCache
    cache_index :slug, :site_id, unique: true
  end
end
