# frozen_string_literal: true

module Folio::Taggable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :tags
    acts_as_taggable_tenant :site_id

    scope :by_tag, -> (tag) { tagged_with(tag) }
    scope :by_tag_id, -> (tag_id) { by_tag(ActsAsTaggableOn::Tag.find_by_id(tag_id)) }
  end
end
