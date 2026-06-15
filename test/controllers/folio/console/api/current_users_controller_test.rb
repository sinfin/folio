# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "console_presence_ping reports no other user when alone" do
    page = create(:folio_page)

    post console_presence_ping_console_api_current_user_url(format: :json),
         params: { record_type: page.class.name, record_id: page.id }

    assert_response(:ok)
    assert_equal false, response.parsed_body["data"]["other_user_at_url"]
    assert_nil response.parsed_body["data"]["bar_html"]
  end

  test "console_presence_ping records presence and bumps console_active_at" do
    page = create(:folio_page)

    post console_presence_ping_console_api_current_user_url(format: :json),
         params: { record_type: page.class.name, record_id: page.id }

    assert_response(:ok)
    assert Folio::ConsolePresence.for_record(page).where(user_id: superadmin.id).exists?
    assert_not_nil superadmin.reload.console_active_at
  end

  test "console_presence_ping returns rendered bar html when another user edits the same record" do
    page = create(:folio_page)
    other = create(:folio_user, :superadmin)
    other.touch_console_presence!(page)

    post console_presence_ping_console_api_current_user_url(format: :json),
         params: { record_type: page.class.name, record_id: page.id }

    assert_response(:ok)
    assert_equal true, response.parsed_body["data"]["other_user_at_url"]
    assert_includes response.parsed_body["data"]["bar_html"].to_s,
                    "f-c-current-users-console-url-bar"
  end

  test "console_presence_ping ignores a non-ActiveRecord record_type" do
    post console_presence_ping_console_api_current_user_url(format: :json),
         params: { record_type: "String", record_id: "1" }

    assert_response(:ok)
    assert_equal false, response.parsed_body["data"]["other_user_at_url"]
  end

  test "console_presence_clear removes only the targeted record's presence and leaves others intact" do
    page = create(:folio_page)
    other_page = create(:folio_page)
    superadmin.touch_console_presence!(page)
    superadmin.touch_console_presence!(other_page)

    post console_presence_clear_console_api_current_user_url(format: :json),
         params: { record_type: page.class.name, record_id: page.id }

    assert_response(:no_content)
    assert_equal 0, Folio::ConsolePresence.for_record(page).where(user_id: superadmin.id).count
    assert_equal 1, Folio::ConsolePresence.for_record(other_page).where(user_id: superadmin.id).count
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
