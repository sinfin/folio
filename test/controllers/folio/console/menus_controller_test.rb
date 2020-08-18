# frozen_string_literal: true

require "test_helper"

class Folio::Console::MenusControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::Menu])
    assert_response :success
  end

  test "edit" do
    menu = create(:folio_menu_with_menu_items)
    get url_for([:edit, :console, menu])
    assert_response :success
  end

  test "update" do
    menu = create(:folio_menu)
    assert_equal(0, menu.menu_items.count)

    put url_for([:console, menu]), params: {
      menu: {
        menu_items_attributes: {
          "0" => {
            id: "",
            unique_id: "1",
            title: "foo"
          }
        }
      },
    }
    assert_redirected_to url_for([:edit, :console, menu])
    assert_equal(1, menu.menu_items.count)
  end
end
