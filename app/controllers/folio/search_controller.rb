# frozen_string_literal: true

module Folio
  class SearchController < BaseController
    include SearchControllerBase

    def show
      super
      @title = t('search.title', query: @query)
      add_breadcrumb @title
    end
  end
end
