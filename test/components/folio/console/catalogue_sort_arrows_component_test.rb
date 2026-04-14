# frozen_string_literal: true

require "test_helper"

class Folio::Console::CatalogueSortArrowsComponentTest < Folio::Console::ComponentTest
  class SortablePage < Folio::Page
    scope :sort_by_title_asc, -> { order(title: :asc) }
    scope :sort_by_title_desc, -> { order(title: :desc) }
  end

  test "render" do
    render_inline(Folio::Console::CatalogueSortArrowsComponent.new(klass: Folio::Page, attr: :title))

    assert_no_selector(".f-c-catalogue-sort-arrows")

    render_inline(Folio::Console::CatalogueSortArrowsComponent.new(klass: SortablePage, attr: :title))

    assert_selector(".f-c-catalogue-sort-arrows")
  end
end
