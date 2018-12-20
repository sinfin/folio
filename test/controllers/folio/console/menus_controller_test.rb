# frozen_string_literal: true

require 'test_helper'

module Folio
  class Console::MenusControllerTest < Console::BaseControllerTest
    setup do
      @menu = create(:folio_menu_with_menu_items)
    end

    test 'should get index' do
      get console_menus_url
      assert_response :success
    end

    test 'should get new' do
      get new_console_menu_url
      assert_response :success
    end

    test 'should get edit' do
      get edit_console_menu_url(@menu)
      assert_response :success
    end

    test 'should not get show for non-nestable' do
      assert_raises(ActionController::MethodNotAllowed) do
        get console_menu_url(@menu)
      end
    end

    test 'should get show for nestable' do
      @menu = ::Menu::Nestable.create!(locale: :cs)
      get console_menu_url(@menu)
      assert_response :ok
    end
  end
end
