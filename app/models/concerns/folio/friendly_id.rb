# frozen_string_literal: true

module Folio::FriendlyId
  extend ActiveSupport::Concern

  included do
    include Folio::FriendlyId::History
    include Folio::FriendlyId::SlugValidation::MultipleClasses

    if defined?(self::FRIENDLY_ID_SCOPE)
      friendly_id :slug_candidates, use: %i[slugged history scoped], scope: self::FRIENDLY_ID_SCOPE

      validates :slug,
                presence: true,
                uniqueness: { scope: self::FRIENDLY_ID_SCOPE },
                format: { with: /[0-9a-z-]+/ },
                if: -> { errors[:slug].blank? }

    else
      friendly_id :slug_candidates, use: %i[slugged history]

      validates :slug,
                presence: true,
                uniqueness: true,
                format: { with: /[0-9a-z-]+/ }
    end

    before_validation :strip_and_downcase_slug

    # Get the instance's friendly_id.
    # overriden from https://github.com/norman/friendly_id/blob/c288abb863cc0ad3a57131f1047542969776ecb7/lib/friendly_id/base.rb#L257
    # we need to handle changes so that forms don't lead to a non-existent slug
    def friendly_id
      column_name = friendly_id_config.query_field

      if changed? && changed_attributes.present? && changed_attributes[column_name].present?
        changed_attributes[column_name]
      else
        super
      end
    end
  end

  private
    def slug_candidates
      # fixes https://github.com/norman/friendly_id/issues/983
      %i[slug to_label]
    end

    def strip_and_downcase_slug
      if slug.present?
        self.slug = slug.strip.downcase.parameterize
      end
    end
end
