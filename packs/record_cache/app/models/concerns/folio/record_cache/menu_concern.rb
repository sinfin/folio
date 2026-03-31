# frozen_string_literal: true

# Primary-key identity cache only. Composite (type, site_id, locale) is not indexed — the schema
# does not enforce uniqueness on that tuple.
module Folio::RecordCache::MenuConcern
  extend ActiveSupport::Concern
  include Folio::RecordCache::BaseConcern

  included do
    include IdentityCache
  end
end
