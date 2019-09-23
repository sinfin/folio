# frozen_string_literal: true

require 'test_helper'

class Folio::Console::MenusControllerTest < Folio::Console::BaseControllerTest
  test 'index' do
    get url_for([:console, Folio::Menu])
    assert_response :success
  end

  test 'edit' do
    menu = create(:folio_menu_with_menu_items)
    get url_for([:edit, :console, menu])
    assert_response :success
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
end
