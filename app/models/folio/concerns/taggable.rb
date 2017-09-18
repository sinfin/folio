# frozen_string_literal: true

module Folio
  module Taggable
    extend ActiveSupport::Concern

    included do
      acts_as_taggable

      # https://github.com/mbleigh/acts-as-taggable-on/issues/808
      # scope :by_tag, -> (tag) { tagged_with(tag) }
      scope :by_tag, -> (tag) { joins(:tags).where(tags: { name: tag }) }
    end
  end
end
