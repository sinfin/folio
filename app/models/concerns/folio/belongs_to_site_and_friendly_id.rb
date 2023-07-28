# frozen_string_literal: true

module Folio::BelongsToSiteAndFriendlyId
  extend ActiveSupport::Concern

  included do
    include Folio::BelongsToSite

    const_set(:FRIENDLY_ID_SCOPE, :site_id)
    include Folio::FriendlyId

    private
      def should_generate_new_friendly_id?
        send(friendly_id_config.slug_column).nil? && super
      end

      def slug_candidates
        %i[slug to_label site_slug_candidate]
      end

      def site_slug_candidate
        if site
          "#{site.slug} #{to_label}"
        end
      end
  end
end
