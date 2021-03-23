# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MenuCellTest < Cell::TestCase
  test "show" do
    menu = Dummy::Menu::Header.create!(locale: :en)

    html = cell("dummy/ui/menu", menu).(:show)
    assert html.has_css?(".d-ui-menu")
  end
end
