# frozen_string_literal: true

require "test_helper"

class Folio::Console::Atoms::PreviewsCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/atoms/previews", nil, klass: Folio::Page).(:show)
    assert_not html.has_css?(".f-c-atoms-previews")

    html = cell("folio/console/atoms/previews", { cs: [] }, klass: Folio::Page).(:show)
    assert html.has_css?(".f-c-atoms-previews")
  end
end
