# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Api::ImagesControllerTest < Folio::Console::BaseControllerTest
  test 'index' do
    get url_for([:console, :api, Folio::Image])
    assert_response :success
  end

  test 'create' do
    assert_equal(0, Folio::Image.count)
    post url_for([:console, :api, Folio::Image]), params: {
      file: {
        attributes: {
          file: fixture_file_upload('test/fixtures/folio/test.gif'),
          type: 'Folio::Image',
        }
      }
    }
    assert_response :success
    assert_equal(1, Folio::Image.count)
  end

  test 'update' do
    image = create(:folio_image)
    put url_for([:console, :api, image]), params: {
      file: {
        attributes: {
          tags: ['foo'],
        }
      }
    }
    assert_response(:success)
    json = JSON.parse(response.body)
    assert_equal(['foo'], json['data']['attributes']['tags'])
  end

  test 'tag' do
    images = create_list(:folio_image, 2)
    assert_equal([], images.first.tag_list)
    assert_equal([], images.second.tag_list)

    post url_for([:tag, :console, :api, Folio::Image]), params: {
      file_ids: images.pluck(:id),
      tags: ['a', 'b'],
    }

    assert_equal(['a', 'b'], images.first.reload.tag_list.sort)
    assert_equal(['a', 'b'], images.second.reload.tag_list.sort)
  end
end
