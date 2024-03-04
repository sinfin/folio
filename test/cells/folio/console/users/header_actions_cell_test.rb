# frozen_string_literal: true

require "test_helper"

class Folio::Console::Users::HeaderActionsCellTest < Folio::Console::CellTest
#  include Devise::Test::ControllerHelpers

  test "show" do
    skip "TODO: fix this test to make working `can_now?` method"
    user = create(:folio_user)
    html = cell("folio/console/users/header_actions", user, { current_user: create(:folio_user, :superadmin) }).(:show)
    assert html.has_css?(".f-c-users-header-actions")
  end
end
