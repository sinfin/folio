# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::HeaderCellTest < Cell::TestCase
  test "show" do
    create_and_host_site

    html = cell("dummy/ui/header", nil).(:show)
    assert html.has_css?(".d-ui-header")

    Dummy::Menu::Header.create!(locale: :en, site: @site)
    html = cell("dummy/ui/header", nil).(:show)
    assert html.has_css?(".d-ui-header")
  end
end
