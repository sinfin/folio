# frozen_string_literal: true

require "test_helper"

class Folio::Console::CatalogueSortArrowsCellTest < Folio::Console::CellTest
  class SortablePage < Folio::Page
    scope :sort_by_title_asc, -> { order(title: :asc) }
    scope :sort_by_title_desc, -> { order(title: :desc) }
  end

  test "show" do
    html = cell("folio/console/catalogue_sort_arrows", klass: Folio::Page, attr: :title).(:show)
    assert_not html.has_css?(".f-c-catalogue-sort-arrows")

    html = cell("folio/console/catalogue_sort_arrows", klass: SortablePage, attr: :title).(:show)
    assert html.has_css?(".f-c-catalogue-sort-arrows")
  end
end
