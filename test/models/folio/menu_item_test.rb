# frozen_string_literal: true

require 'test_helper'

module Folio
  class MenuItemTest < ActiveSupport::TestCase
    test 'respects menu locale' do
      cs_menu = create(:folio_menu, locale: :cs)
      cs_node = create(:folio_node, locale: :cs)
      en_node = create(:folio_node, locale: :en)

      item = build(:folio_menu_item, target: cs_node, menu: cs_menu)
      assert item.valid?
      cs_menu.items << item
      assert cs_menu.save

      item = build(:folio_menu_item, target: en_node, menu: cs_menu)
      refute item.valid?
      cs_menu.items << item
      refute cs_menu.save
    end

    class StrictMenu < Menu
      def self.allowed_menu_item_classes
        []
      end
    end

    test 'respects menu allowed types' do
      strict_menu = StrictMenu.create!(locale: :cs)
      assert strict_menu

      item = build(:folio_menu_item, menu: strict_menu)
      refute item.valid?
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
