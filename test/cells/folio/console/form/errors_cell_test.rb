# frozen_string_literal: true

require "test_helper"

class Folio::Console::Form::ErrorsCellTest < Folio::Console::CellTest
  test "show" do
    page = build(:folio_page, title: nil)
    page.valid?
    html = cell("folio/console/form/errors", nil, errors: page.errors).(:show)
    assert html.has_css?(".f-c-form-errors")
  end
end
