# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "console_url_ping" do
    assert_nil superadmin.console_url
    assert_nil superadmin.console_url_updated_at

    post console_url_ping_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:ok)
    assert_equal false, response.parsed_body["data"]["other_user_at_url"]

    superadmin.reload

    assert_equal "foo", superadmin.console_url
    assert superadmin.console_url_updated_at
  end

  test "console_url_ping returns other_user_at_url when another user edits the url" do
    other_user = create(:folio_user, :superadmin)
    other_user.update_console_url!("foo")

    post console_url_ping_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:ok)
    assert_equal true, response.parsed_body["data"]["other_user_at_url"]
  end

  test "console_url_ping ignores other users with stale console_url" do
    other_user = create(:folio_user, :superadmin)
    other_user.update_columns(console_url: "foo",
                              console_url_updated_at: 10.minutes.ago)

    post console_url_ping_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:ok)
    assert_equal false, response.parsed_body["data"]["other_user_at_url"]
  end

  test "console_url_clear clears console_url" do
    superadmin.update_console_url!("foo")

    post console_url_clear_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:no_content)

    superadmin.reload

    assert_nil superadmin.console_url
    assert_nil superadmin.console_url_updated_at
  end

  test "console_url_clear keeps console_url when url param does not match" do
    superadmin.update_console_url!("bar")

    post console_url_clear_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:no_content)

    superadmin.reload

    assert_equal "bar", superadmin.console_url
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
