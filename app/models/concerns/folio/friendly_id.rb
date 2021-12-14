# frozen_string_literal: true

module Folio::FriendlyId
  extend ActiveSupport::Concern

  included do
    extend FriendlyId

    if defined?(self::FRIENDLY_ID_SCOPE)
      friendly_id :slug_candidates, use: %i[slugged history scoped], scope: self::FRIENDLY_ID_SCOPE

      validates :slug,
                presence: true,
                uniqueness: { scope: self::FRIENDLY_ID_SCOPE },
                format: { with: /[0-9a-z-]+/ }
    else
      friendly_id :slug_candidates, use: %i[slugged history]

      validates :slug,
                presence: true,
                uniqueness: true,
                format: { with: /[0-9a-z-]+/ }
    end

    before_validation :strip_and_downcase_slug
  end

  private
    def slug_candidates
      %i[to_label]
    end

    def strip_and_downcase_slug
      if slug.present?
        self.slug = slug.strip.downcase.parameterize
      end
    end
end
