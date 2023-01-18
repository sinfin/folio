# frozen_string_literal: true

module Folio::BelongsToSiteAndFriendlyId
  extend ActiveSupport::Concern

  included do
    include Folio::BelongsToSite

    const_set(:FRIENDLY_ID_SCOPE, :site_id)
    include Folio::FriendlyId

    private
      def slug_candidates
        if site
          [
            slug.presence,
            to_label,
            "#{site.slug} #{to_label}",
            "#{site.slug} #{to_label} 2",
            "#{site.slug} #{to_label} 3",
          ].compact
        else
          %i[slug to_label]
        end
      end
  end
end
