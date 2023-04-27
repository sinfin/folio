# frozen_string_literal: true

require "test_helper"

class Folio::PlayerCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/player", create(:folio_file_audio)).(:show)
    assert html.has_css?(".f-player")
  end
end
