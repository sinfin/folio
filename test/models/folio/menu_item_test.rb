# frozen_string_literal: true

require 'test_helper'

module Folio
  class MenuItemTest < ActiveSupport::TestCase
    test 'respects menu locale' do
      cs_menu = create(:folio_menu, locale: :cs)
      cs_page = create(:folio_page, locale: :cs)
      en_page = create(:folio_page, locale: :en)

      item = build(:folio_menu_item, target: cs_page, menu: cs_menu)
      assert item.valid?
      cs_menu.items << item
      assert cs_menu.save

      item = build(:folio_menu_item, target: en_page, menu: cs_menu)
      assert_not item.valid?
      cs_menu.items << item
      assert_not cs_menu.save
    end

    class StrictMenu < Menu
      def self.allowed_menu_item_classes
        []
      end
    end

    class MenuWithRailsPaths < Menu
      def self.rails_paths
        {
          root_path: 'foo',
        }
      end
    end

    test 'respects menu allowed types' do
      strict_menu = StrictMenu.create!(locale: :cs)
      assert strict_menu

      item = build(:folio_menu_item, menu: strict_menu)
      assert_not item.valid?
    end

    test 'respects menu available targets and rails_paths' do
      menu = MenuWithRailsPaths.create!(locale: :cs)

      assert create(:folio_menu_item, menu: menu, rails_path: 'root_path')

      assert_raises(ActiveRecord::RecordInvalid) do
        create(:folio_menu_item, menu: menu, target: menu)
      end

      assert_raises(ActiveRecord::RecordInvalid) do
        create(:folio_menu_item, menu: menu, rails_path: 'nope_path')
      end
    end
  end
end

# == Schema Information
#
# Table name: folio_menu_items
#
#  id          :integer          not null, primary key
#  menu_id     :integer
#  type        :string
#  ancestry    :string
#  title       :string
#  rails_path  :string
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  target_type :string
#  target_id   :integer
#
# Indexes
#
#  index_folio_menu_items_on_ancestry                   (ancestry)
#  index_folio_menu_items_on_menu_id                    (menu_id)
#  index_folio_menu_items_on_target_type_and_target_id  (target_type,target_id)
#  index_folio_menu_items_on_type                       (type)
#
