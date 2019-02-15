# frozen_string_literal: true

require 'test_helper'

class Folio::Console::MenusControllerTest < Folio::Console::BaseControllerTest
  test 'index' do
    get url_for([:console, Folio::Menu])
    assert_response :success
  end

  test 'new' do
    get url_for([:console, Folio::Menu, action: :new])
    assert_response :success
  end

  test 'edit' do
    menu = create(:folio_menu_with_menu_items)
    get url_for([:edit, :console, menu])
    assert_response :success
  end

  test 'should not get show for non-nestable' do
    menu = create(:folio_menu_with_menu_items)

    assert_raises(ActionController::MethodNotAllowed) do
      get url_for([:console, menu])
    end
  end

  test 'show for nestable' do
    menu = Dummy::Menu::Nestable.create!(locale: :cs)
    get url_for([:console, menu])
    assert_response :ok
  end

  test 'create' do
    params = build(:folio_menu).serializable_hash
    assert_equal(0, Folio::Menu.count)
    post url_for([:console, Folio::Menu]), params: {
      menu: params.merge(type: 'Dummy::Menu::Nestable'),
    }
    assert_equal(1, Folio::Menu.count, 'Creates record')
    assert_redirected_to url_for([:console, Folio::Menu])
  end

  test 'update' do
    menu = create(:folio_menu)
    assert_not_equal('en', menu.locale)
    put url_for([:console, menu]), params: {
      menu: {
        locale: 'en',
      },
    }
    assert_redirected_to url_for([:edit, :console, menu])
    assert_equal('en', menu.reload.locale)
  end

  test 'destroy' do
    menu = create(:folio_menu)
    delete url_for([:console, menu])
    assert_redirected_to url_for([:console, Folio::Menu])
    assert_not(Folio::Menu.exists?(id: menu.id))
  end

  test 'tree_sort' do
    menu = create(:folio_menu_with_menu_items)

    item_1, item_2, item_3 = menu.menu_items

    assert_not_equal item_1.id, item_2.parent_id

    post url_for([:tree_sort, :console, menu]), params: {
      sortable: {
        '0' => { id: item_1.id, parent_id: nil },
        '1' => { id: item_2.id, parent_id: item_1.id },
        '2' => { id: item_3.id, parent_id: nil },
      }
    }
    assert_response :success

    assert_equal item_1.id, item_2.reload.parent_id
  end
end
