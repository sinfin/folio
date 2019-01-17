# frozen_string_literal: true

require 'test_helper'

class Folio::Console::MenuTreeCellTest < Folio::Console::CellTest
  test 'show' do
    menu = create(:folio_menu)
    2.times { create(:folio_menu_item, menu: menu) }
    root = create(:folio_menu_item, menu: menu)
    son = create(:folio_menu_item, menu: menu, parent: root)
    create(:folio_menu_item, menu: menu, parent: son)

    html = cell('folio/console/menu_tree',
      menu: menu,
      items: menu.menu_items.roots.ordered,
      url: controller.console_menu_path(menu),
      root: true,
    ).(:show)

    assert_equal(5, html.find_all('li').size)
    assert_equal(3, html.find_all('ol').size)
    assert_equal(1, html.find_all('.folio-console-menu-items-structure--root').size)
  end
end
