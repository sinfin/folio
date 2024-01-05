# frozen_string_literal: true

require "test_helper"

class Folio::MenuItemTest < ActiveSupport::TestCase
  class MenuWithRailsPaths < ::Folio::Menu
    def self.rails_paths
      {
        root_path: "foo",
      }
    end
  end

  class StylableMenu < ::Folio::Menu
    def self.styles
      %w[red]
    end
  end

  test "requires target/rails_path" do
    menu = MenuWithRailsPaths.create!(locale: :cs, site: get_any_site)
    assert menu

    item = build(:folio_menu_item, menu:)
    assert_not item.valid?
    assert item.errors[:target]
  end

  test "respects menu available targets and rails_paths" do
    menu = MenuWithRailsPaths.create!(locale: :cs, site: get_any_site)

    assert create(:folio_menu_item, menu:, rails_path: "root_path")

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:folio_menu_item, menu:, target: menu)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:folio_menu_item, menu:, rails_path: "nope_path")
    end
  end

  test "set_specific_relations" do
    menu = create(:folio_menu_page)
    page = create(:folio_page)
    menu_item = create(:folio_menu_item, menu:, target: page)
    assert_equal(page.id, menu_item.folio_page_id)
    assert_equal(page, menu_item.page)
  end

  test "validate_style" do
    menu = StylableMenu.create!(locale: :cs, site: get_any_site)
    page = create(:folio_page)

    assert build(:folio_menu_item, menu:, target: page, style: nil).valid?
    assert build(:folio_menu_item, menu:, target: page, style: "red").valid?
    assert_not build(:folio_menu_item, menu:, target: page, style: "foo").valid?

    menu = create(:folio_menu_page)
    assert build(:folio_menu_item, menu:, target: page, style: nil).valid?
    assert_not build(:folio_menu_item, menu:, target: page, style: "red").valid?
    assert_not build(:folio_menu_item, menu:, target: page, style: "foo").valid?
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
