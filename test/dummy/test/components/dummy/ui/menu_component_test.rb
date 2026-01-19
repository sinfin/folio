# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::MenuComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    menu = Dummy::Menu::Header.create!(site: @site, locale: @site.locale)

    render_inline(Dummy::Ui::MenuComponent.new(menu:))

    assert_selector(".d-ui-menu")
  end
end
