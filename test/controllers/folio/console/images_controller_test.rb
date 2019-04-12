# frozen_string_literal: true

require 'test_helper'

class Folio::Console::ImagesControllerTest < Folio::Console::BaseControllerTest
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
    assert_equal(0, Folio::Image.count)
    post console_images_url, params: {
      image: {
        file: fixture_file_upload('test/fixtures/folio/test.gif'),
        type: 'Folio::Image',
      }
    }
    assert_response :success
    assert_equal(1, Folio::Image.count)
  end

  test 'update' do
    image = create(:folio_image)
    put console_image_url(image), params: {
      image: {
        tag_list: 'foo'
      }
    }
    assert_redirected_to console_images_path
    assert_equal(['foo'], image.reload.tag_list)
  end

  test 'destroy' do
    image = create(:folio_image)
    assert_equal(1, Folio::Image.count)
    delete console_image_url(image)
    assert_equal(0, Folio::Image.count)
  end

  test 'tag' do
    images = create_list(:folio_image, 2)
    assert_equal([], images.first.tag_list)
    assert_equal([], images.second.tag_list)

    post tag_console_images_path, params: {
      file_ids: images.pluck(:id),
      tags: ['a', 'b'],
    }

    assert_equal(['a', 'b'], images.first.reload.tag_list.sort)
    assert_equal(['a', 'b'], images.second.reload.tag_list.sort)
  end
end
