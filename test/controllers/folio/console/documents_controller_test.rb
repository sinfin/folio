# frozen_string_literal: true

require "test_helper"

class Folio::Console::DocumentsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::Document])
    assert_response :success
  end
end
