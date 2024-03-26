# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "console_path_ping" do
    assert_nil superadmin.console_path
    assert_nil superadmin.console_path_updated_at

    post console_path_ping_console_api_current_user_path, params: { path: "foo" }
    assert_response(:ok)

    superadmin.reload

    assert_equal "foo", superadmin.console_path
    assert superadmin.console_path_updated_at
  end
end
