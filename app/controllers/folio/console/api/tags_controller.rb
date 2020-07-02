# frozen_string_literal: true

class Folio::Console::Api::TagsController < Folio::Console::Api::BaseController
  def react_select
    q = params[:q]

    scope = ActsAsTaggableOn::Tag.most_used

    if q.present?
      scope = scope.by_query(q)
    else
      scope = scope.all
    end

    response = scope.first(7).pluck(:name)

    render json: { data: response }
  end
end
