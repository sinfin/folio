# frozen_string_literal: true

class Folio::Console::Api::TagsController < Folio::Console::Api::BaseController
  def index
    q = params[:q]
    context = params[:context].presence || "tags"

    scope = ActsAsTaggableOn::Tag.joins(:taggings)
                                 .where(taggings: { context:, tenant: Folio::Current.site.id })

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
