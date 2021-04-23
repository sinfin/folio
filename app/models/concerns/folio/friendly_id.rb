# frozen_string_literal: true

module Folio::FriendlyId
  extend ActiveSupport::Concern

  included do
    extend FriendlyId

    friendly_id :slug_candidate, use: %i[slugged history]

    validates :slug,
              presence: true,
              uniqueness: true,
              format: { with: /[a-z][0-9a-z-]+/ }

    before_validation :strip_and_downcase_slug
  end

  private
    def slug_candidate
      title
    end

    def strip_and_downcase_slug
      if slug.present?
        self.slug = slug.strip.downcase
      end
    end
end
