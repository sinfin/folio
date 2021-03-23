# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::NavigationCellTest < Cell::TestCase
  test "show" do
    menu = Dummy::Menu::Header.create!(locale: :en)

    html = cell("dummy/ui/navigation", menu).(:show)
    assert html.has_css?(".d-ui-navigation")
  end
end
