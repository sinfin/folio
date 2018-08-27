# frozen_string_literal: true

module Folio
  class SearchController < BaseController
    include SearchControllerBase

    def show
      super
      @public_page_title = t('search.title', query: @query)
      add_breadcrumb @public_page_title
    end
  end
end
