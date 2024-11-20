# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "console_url_ping" do
    assert_nil superadmin.console_url
    assert_nil superadmin.console_url_updated_at

    post console_url_ping_console_api_current_user_url, params: { url: "foo" }
    assert_response(:ok)

    superadmin.reload

    assert_equal "foo", superadmin.console_url
    assert superadmin.console_url_updated_at
  end
end
