# frozen_string_literal: true

require 'test_helper'

class Folio::Console::ImagesControllerTest < Folio::Console::BaseControllerTest
  test 'index' do
    get url_for([:console, Folio::Image])
    assert_response :success
  end
end
