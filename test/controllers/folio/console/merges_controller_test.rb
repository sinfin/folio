# frozen_string_literal: true

require 'test_helper'

class Folio::Console::MergesControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test 'new' do
    original = create(:folio_page)
    duplicate = create(:folio_page)

    get new_console_merge_path('Folio::Page', original, duplicate)
    assert_response :success
  end

  test 'create' do
  end
end
