# frozen_string_literal: true

require 'test_helper'

class Folio::Console::PagesControllerTest < Folio::Console::BaseControllerTest
  include Engine.routes.url_helpers

  test 'should get index' do
    get console_pages_url
    assert_response :success
  end

  test 'should get new' do
    get new_console_page_url
    assert_response :success
  end

  test 'should get edit' do
    page = create(:folio_page)
    get edit_console_page_url(page)
    assert_response :success
  end
end
