# frozen_string_literal: true

require 'test_helper'
require_relative 'base_controller_test'

module Folio
  class Console::FilesControllerTest < Console::BaseControllerTest
    setup do
      @image = create(:folio_image)
    end

    test 'should get index' do
      get console_files_url
      assert_response :success
    end

    test 'should get edit' do
      get edit_console_file_url(@image)
      assert_response :success
    end
  end
end
