# frozen_string_literal: true

module Folio
  module Publishable
    module Basic
      extend ActiveSupport::Concern

      included do
        scope :published, -> { where(published: true) }
        scope :unpublished, -> { where('published != ? OR published IS NULL', true) }
      end
    end

    module WithDate
      extend ActiveSupport::Concern

      included do
        scope :published, -> {
          where('published = ? OR (published_at IS NOT NULL AND published_at <= ?)', true, Time.now.change(sec: 0))
        }

        scope :unpublished, -> {
          where('(published != ? OR published IS NULL) AND (published_at IS NULL OR published_at > ?)', true, Time.now.change(sec: 0))
        }
      end
    end
  end
end
