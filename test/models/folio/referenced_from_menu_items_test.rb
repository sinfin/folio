# frozen_string_literal: true

require 'test_helper'

module Folio
  class ReferencedFromMenuItemsTest < ActiveSupport::TestCase
    test 'deletes referenced menu_items' do
      node = create(:folio_node)

      menu = create(:folio_menu)
      menu_item = menu.menu_items.create!(target: node)

      node.destroy!
      assert_not MenuItem.exists?(id: menu_item.id)
    end

    test 'destroys referenced menu_items on unpublishing' do
      node = create(:folio_node)

      menu = create(:folio_menu)
      menu_item = menu.menu_items.create!(target: node)

      node.update!(published: false)
      assert_not MenuItem.exists?(id: menu_item.id)
    end
  end
end
