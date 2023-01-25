# frozen_string_literal: true

module Folio::FriendlyIdWithLocale
  extend ActiveSupport::Concern

  included do
    const_set(:FRIENDLY_ID_SCOPE, :locale)
    include Folio::FriendlyId

    private
      def slug_candidates
        [
          slug.presence,
          to_label,
          "#{locale} #{to_label}",
          "#{locale} #{to_label} 2",
          "#{locale} #{to_label} 3",
        ].compact
      end
  end
end
