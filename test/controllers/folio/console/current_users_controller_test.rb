# frozen_string_literal: true

require "test_helper"

class Folio::Console::CurrentUsersControllerTest < Folio::Console::BaseControllerTest
  test "show" do
    get folio.console_current_user_path
    assert_response(:ok)
    assert_select("h1", I18n.t("folio.console.current_users.show.title"))
  end
end
