# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::EmbedCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/embed", nil).(:show)
    assert html.has_css?(".d-ui-embed")
  end
end
