# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "console_url_ping" do
    assert_nil superadmin.console_url
    assert_nil superadmin.console_url_updated_at

    post console_url_ping_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:ok)

    superadmin.reload

    assert_equal "foo", superadmin.console_url
    assert superadmin.console_url_updated_at
  end

  test "update_console_preference" do
    assert_nil superadmin.console_preferences

    post update_console_preferences_console_api_current_user_path(format: :json), params: {
      html_auto_format: true,
    }
    assert_response(:ok)

    superadmin.reload

    assert_equal true, response.parsed_body["data"]["html_auto_format"]
    assert_equal true, superadmin.console_preferences["html_auto_format"]

    post update_console_preferences_console_api_current_user_path(format: :json), params: {
      html_auto_format: false,
    }
    assert_response(:ok)

    superadmin.reload

    assert_equal false, response.parsed_body["data"]["html_auto_format"]
    assert_equal false, superadmin.console_preferences["html_auto_format"]
  end
end
