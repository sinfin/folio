# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "console_url_ping returns 204 if there is no conflict" do
    assert_nil superadmin.console_url
    assert_nil superadmin.console_url_updated_at

    page = create(:folio_page)
    post console_url_ping_console_api_current_user_url(format: :json), params: { url: "foo" }
    assert_response(:no_content)

    superadmin.reload

    assert_equal "foo", superadmin.console_url
    assert superadmin.console_url_updated_at
  end

  test "console_url_ping returns ConsoleBar content on conflict" do
    # BUT! console url must end with `/edit`

    page = create(:folio_page)

    assert_nil superadmin.console_url
    assert_nil superadmin.console_url_updated_at

    console_url = console_page_path(page)
    user2 = create(:folio_user, console_url:, console_url_updated_at: Time.current - 10.seconds)
    params = { url: console_url, record_id: page.id, record_type: page.class.name }

    post console_url_ping_console_api_current_user_url(format: :json), params: params

    assert_response(:no_content) # no conflict escalation!

    superadmin.reload

    assert_equal console_url, superadmin.console_url
    assert superadmin.console_url_updated_at

    # no let try edit page

    console_url = edit_console_page_path(page)
    user2.update!(console_url:)
    params[:url] = console_url

    post console_url_ping_console_api_current_user_url(format: :json), params: params

    assert_response(:ok)
    assert_includes response.body, "Tuto stránku nyní upravuje"
    assert_includes response.body, user2.to_label

    superadmin.reload

    assert_equal console_url, superadmin.console_url
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
