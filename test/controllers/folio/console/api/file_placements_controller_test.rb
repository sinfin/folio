# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::FilePlacementsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get console_api_file_placements_path(file_id: create(:folio_file_image).id, format: :json)
    assert_response :success
  end
end
