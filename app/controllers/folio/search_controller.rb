# frozen_string_literal: true

class Folio::SearchController < Folio::BaseController
  include Folio::SearchControllerBase

  def show
    super
    @public_page_title = t('search.title', query: @query)
    add_breadcrumb @public_page_title
  end
end
