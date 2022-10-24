# frozen_string_literal: true

module Folio::BelongsToSiteAndFriendlyId
  extend ActiveSupport::Concern

  include Folio::BelongsToSite

  FRIENDLY_ID_SCOPE = :site_id
  include Folio::FriendlyId

  private
    def slug_candidates
      if site
        [
          to_label,
          "#{site.slug} #{to_label}",
          "#{site.slug} #{to_label} 2",
          "#{site.slug} #{to_label} 3",
        ]
      else
        %i[to_label]
      end
    end
end
