# frozen_string_literal: true

module Folio::FriendlyId
  extend ActiveSupport::Concern

  included do
    extend FriendlyId

    friendly_id :slug_candidates, use: %i[slugged history]

    validates :slug,
              presence: true,
              uniqueness: true,
              format: { with: /[0-9a-z-]+/ }

    before_validation :strip_and_downcase_slug
  end

  private
    def slug_candidates
      to_label
    end

    def strip_and_downcase_slug
      if slug.present?
        self.slug = slug.strip.downcase.parameterize
      end
    end
end
