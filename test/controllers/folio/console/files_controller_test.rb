require 'test_helper'

module Folio
  class Console::FilesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test 'should get index' do
      get console_files_index_url
      assert_response :success
    end

    test 'should get show' do
      get console_files_show_url
      assert_response :success
    end

    test 'should get new' do
      get console_files_new_url
      assert_response :success
    end

    test 'should get create' do
      get console_files_create_url
      assert_response :success
    end

    test 'should get edit' do
      get console_files_edit_url
      assert_response :success
    end

    test 'should get update' do
      get console_files_update_url
      assert_response :success
    end
  end
end
