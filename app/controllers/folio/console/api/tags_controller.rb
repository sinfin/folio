# frozen_string_literal: true

class Folio::Console::Api::TagsController < Folio::Console::Api::BaseController
  def react_select
    q = params[:q]
    context = params[:context].presence || "tags"

    scope = ActsAsTaggableOn::Tag.joins(:taggings)
                                 .where(taggings: { context: context })

    if q.present?
      scope = scope.by_query(q)
    end

    scope = scope.unscope(:order).most_used

    response = scope.limit(7)
                    .select("DISTINCT(tags.name), tags.taggings_count")
                    .map(&:name)

    render json: { data: response }
  end
end
