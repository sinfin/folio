# frozen_string_literal: true

require "test_helper"

class Folio::Console::File::ImagesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::File::Image])
    assert_response :success
  end
end
