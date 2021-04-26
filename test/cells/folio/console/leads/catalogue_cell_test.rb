# frozen_string_literal: true

require "test_helper"

class Folio::Console::Leads::CatalogueCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/leads/catalogue", nil).(:show)
    assert html.has_css?(".f-c-leads-catalogue")
  end
end
