# frozen_string_literal: true

module Folio::Console::FileControllerIndexFilters
  extend ActiveSupport::Concern

  private
    def index_filters
      filters = {
        # TODO: enable with the rest of the filtering changes
        # by_query: { as: :text, icon: :magnify },
        created_by_current_user: { as: :boolean },
        by_used: [true, false],
        by_tag_id: {
          klass: "ActsAsTaggableOn::Tag",
        },
      }

      if @klass.included_modules.include?(Folio::File::HasUsageConstraints)
        filters[:by_usage_constraints] = @klass.usage_constraints_for_select
        filters[:by_media_source] = { klass: "Folio::MediaSource", order_scope: :ordered }

        if Rails.application.config.folio_shared_files_between_sites
          filters[:by_allowed_site_slug] = Folio::Site.ordered.map { |site| [site.to_label, site.slug] }
        end
      end

      filters
    end
end
