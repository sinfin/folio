# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::FilePlacementsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, :api, Folio::Image])
    assert_response :success
  end
end
