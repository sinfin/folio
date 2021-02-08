# frozen_string_literal: true

require "test_helper"

class Folio::Console::TransportsControllerTest < Folio::Console::BaseControllerTest
  test "out" do
    sign_in @admin
    assert_raises(ActiveRecord::RecordNotFound) do
      get out_console_transport_path(class_name: "Folio::Page", id: 1)
    end

    menu = create(:folio_menu)
    sign_in @admin
    assert_raises(ActionController::ParameterMissing) do
      get out_console_transport_path(class_name: "Folio::Menu", id: menu)
    end

    page = create(:folio_page)

    sign_in @admin
    get out_console_transport_path(class_name: "Folio::Page", id: page.id)
    assert_response :success
  end
end
