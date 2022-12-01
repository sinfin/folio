# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::CurrentAccountsControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "console_path_ping" do
    assert_nil @admin.console_path
    assert_nil @admin.console_path_updated_at

    post console_path_ping_console_api_current_account_path, params: { path: "foo" }
    assert_response(:ok)

    @admin.reload

    assert_equal "foo", @admin.console_path
    assert @admin.console_path_updated_at
  end
end
