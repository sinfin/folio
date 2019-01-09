# frozen_string_literal: true

module Folio::Publishable
  module Basic
    extend ActiveSupport::Concern

    included do
      scope :published, -> { where(published: true) }
      scope :unpublished, -> { where('published != ? OR published IS NULL', true) }
    end

    def published?
      published.present?
    end
  end

  module WithDate
    extend ActiveSupport::Concern

    included do
      scope :published, -> {
        where('published = ? AND (published_at IS NOT NULL AND published_at <= ?)', true, Time.now.change(sec: 0))
      }

      scope :unpublished, -> {
        where('(published != ? OR published IS NULL) OR (published_at IS NULL OR published_at > ?)', true, Time.now.change(sec: 0))
      }
    end

    def published?
      published.present? &&
      published_at &&
      published_at <= Time.now.change(sec: 0)
    end
  end
end
