# frozen_string_literal: true

require "test_helper"

class Folio::PlayerCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/player", nil).(:show)
    assert html.has_css?(".folio--folio-player")
  end
end
