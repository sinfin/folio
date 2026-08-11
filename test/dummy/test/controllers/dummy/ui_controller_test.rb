# frozen_string_literal: true

require "test_helper"

class Dummy::UiControllerTest < Folio::BaseControllerTest
  test "folio_icons" do
    get folio_icons_dummy_ui_path

    assert_response :success
    assert_select "h2", text: "Folio Icons"
    assert_select "small", text: "calendar_with_exclamation"
  end
end
