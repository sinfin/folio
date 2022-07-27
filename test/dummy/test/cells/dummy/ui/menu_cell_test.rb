# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MenuCellTest < Cell::TestCase
  test "show" do
    create_and_host_site

    menu = Dummy::Menu::Header.create!(locale: :en, site: @site)

    html = cell("dummy/ui/menu", menu).(:show)
    assert html.has_css?(".d-ui-menu")
  end
end
