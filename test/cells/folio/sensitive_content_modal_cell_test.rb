# frozen_string_literal: true

require "test_helper"

class Folio::SensitiveContentModalCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/sensitive_content_modal", nil).(:show)
    assert html.has_css?(".f-sensitive-content-modal")
  end
end
