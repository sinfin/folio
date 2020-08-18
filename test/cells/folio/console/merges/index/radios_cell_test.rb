# frozen_string_literal: true

require "test_helper"

class Folio::Console::Merges::Index::RadiosCellTest < Folio::Console::CellTest
  test "show" do
    model = create(:folio_page)
    html = cell("folio/console/merges/index/radios", model).(:show)
    assert html.has_css?(".f-c-merges-index-radios")
  end
end
