# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::FlashCellTest < Cell::TestCase
  test "no flash" do
    html = cell("dummy/ui/flash", nil).(:show)
    assert_equal 0, html.find_css(".container").length
    assert_equal 0, html.find_css(".alert").length
  end

  test "danger flash" do
    flash_hash = ActionDispatch::Flash::FlashHash.new
    flash_hash[:error] = "foo"
    html = cell("dummy/ui/flash", flash_hash).(:show)
    assert html.has_css?(".alert-danger")
  end
end
