# frozen_string_literal: true

require 'test_helper'

class Folio::Console::DocumentsControllerTest < Folio::Console::BaseControllerTest
  test 'index' do
    get url_for([:console, Folio::Document])
    assert_response :success
  end

  test 'edit' do
    document = create(:folio_document)
    get url_for([:edit, :console, document])
    assert_response :success
  end

  test 'update' do
    document = create(:folio_document)
    put url_for([:console, document]), params: {
      file: {
        tag_list: 'foo'
      }
    }
    assert_redirected_to url_for([:edit, :console, document])
    assert_equal(['foo'], document.reload.tag_list)
  end

  test 'destroy' do
    document = create(:folio_document)
    assert_equal(1, Folio::Document.count)
    delete url_for([:console, document])
    assert_equal(0, Folio::Document.count)
  end
end
