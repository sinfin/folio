# frozen_string_literal: true

module Folio::Taggable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable

    scope :by_tag, -> (tag) { tagged_with(tag) }
  end
end
