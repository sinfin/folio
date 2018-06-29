# frozen_string_literal: true

require 'test_helper'
require_relative 'base_controller_test'

module Folio
  class Console::ImagesControllerTest < Console::BaseControllerTest
    test 'index' do
      get console_images_url
      assert_response :success
    end

    test 'edit' do
      image = create(:folio_image)
      get edit_console_image_url(image)
      assert_response :success
    end

    test 'create' do
      assert_equal(0, Image.count)
      post console_images_url, params: {
        file: {
          file: fixture_file_upload('test/fixtures/folio/test.gif'),
          type: 'Folio::Image',
        }
      }
      assert_response :success
      assert_equal(1, Image.count)
    end

    test 'update' do
      image = create(:folio_image)
      put console_image_url(image), params: {
        file: {
          tag_list: 'foo'
        }
      }
      assert_redirected_to console_images_path
      assert_equal(['foo'], image.reload.tag_list)
    end

    test 'destroy' do
      image = create(:folio_image)
      assert_equal(1, Image.count)
      delete console_image_url(image)
      assert_equal(0, Image.count)
    end
  end
end
