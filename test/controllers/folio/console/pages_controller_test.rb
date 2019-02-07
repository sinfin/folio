# frozen_string_literal: true

require 'test_helper'

class Folio::Console::PagesControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test 'should get index' do
    get url_for([:console, Folio::Page])
    assert_response :success
  end

  test 'should get new' do
    get url_for([:console, Folio::Page, action: :new])
    assert_response :success
  end

  test 'should get edit' do
    page = create(:folio_page)
    get url_for([:edit, :console, page])
    assert_response :success
  end
end
