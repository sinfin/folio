# frozen_string_literal: true

require 'test_helper'

class Folio::Console::ImagesControllerTest < Folio::Console::BaseControllerTest
  test 'index' do
    get url_for([:console, Folio::Image])
    assert_response :success
  end

  test 'edit' do
    image = create(:folio_image)
    get url_for([:edit, :console, image])
    assert_response :success
  end

  test 'update' do
    image = create(:folio_image)
    put url_for([:console, image]), params: {
      file: {
        tag_list: 'foo'
      }
    }
    assert_redirected_to url_for([:edit, :console, image])
    assert_equal(['foo'], image.reload.tag_list)
  end

  test 'destroy' do
    image = create(:folio_image)
    assert_equal(1, Folio::Image.count)
    delete url_for([:console, image])
    assert_equal(0, Folio::Image.count)
  end

  test 'mass_download' do
    images = create_list(:folio_image, 2)
    ids = images.map(&:id).join(',')
    get url_for([:mass_download, :console, Folio::Image, ids: ids])
    assert_response(:ok)
  end
end
