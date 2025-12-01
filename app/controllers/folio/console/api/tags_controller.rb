# frozen_string_literal: true

class Folio::Console::Api::TagsController < Folio::Console::Api::BaseController
  def index
    q = params[:q]
    context = params[:context].presence || "tags"

    tenant_site_ids = [Folio::Current.site.id]
    if Rails.application.config.folio_shared_files_between_sites
      tenant_site_ids << Folio::Current.main_site.id
    end
    scope = ActsAsTaggableOn::Tag.joins(:taggings)
                                 .where(taggings: { context:, tenant: tenant_site_ids.compact.uniq })

    if q.present?
      scope = scope.by_label_query(q)
    end

    scope = scope.unscope(:order).most_used(7)

    response = scope.limit(7)
                    .select("DISTINCT(tags.name), tags.taggings_count, tags.id")
                    .map(&:name)

    render json: { data: response }
  end
end
