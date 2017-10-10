require_dependency 'folio/application_controller'

module Folio
  class SearchController < BaseController
    def show
      @query = ActionController::Base.helpers.sanitize(params[:q].to_s)
      @title = t('search.title', query: @query)
      add_breadcrumb @title

      @results = PgSearch.multisearch(@query).includes(:searchable).page(params[:page].to_i || 1)
    end
  end
end
