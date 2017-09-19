require 'test_helper'

module Folio
  class Console::MenusControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test 'should get index' do
      get console_menus_index_url
      assert_response :success
    end

    test 'should get new' do
      get console_menus_new_url
      assert_response :success
    end

    test 'should get edit' do
      get console_menus_edit_url
      assert_response :success
    end
  end
end
