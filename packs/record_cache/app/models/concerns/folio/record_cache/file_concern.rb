# frozen_string_literal: true

module Folio::RecordCache::FileConcern
  extend ActiveSupport::Concern
  include Folio::RecordCache::BaseConcern

  included do
    include IdentityCache
  end
end
