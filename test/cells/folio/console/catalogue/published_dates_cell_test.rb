# frozen_string_literal: true

require "test_helper"

class Folio::Console::Catalogue::PublishedDatesCellTest < Folio::Console::CellTest
  test "show" do
    page = create(:folio_page)
    html = cell("folio/console/catalogue/published_dates", page).(:show)
    assert html.has_css?(".f-c-catalogue-published-dates")
  end
end
