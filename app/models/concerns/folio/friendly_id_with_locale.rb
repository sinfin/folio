# frozen_string_literal: true

module Folio::FriendlyIdWithLocale
  extend ActiveSupport::Concern

  included do
    const_set(:FRIENDLY_ID_SCOPE, :locale)
    include Folio::FriendlyId

    private
      def should_generate_new_friendly_id?
        send(friendly_id_config.slug_column).nil? && super
      end

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
