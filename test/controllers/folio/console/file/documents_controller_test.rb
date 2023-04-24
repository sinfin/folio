# frozen_string_literal: true

require "test_helper"

class Folio::Console::File::DocumentsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::File::Document])
    assert_response :success
  end
end
