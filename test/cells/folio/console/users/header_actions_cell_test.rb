# frozen_string_literal: true

require "test_helper"

class Folio::Console::Users::HeaderActionsCellTest < Folio::Console::CellTest
  test "show" do
    user = create(:folio_user)
    html = cell("folio/console/users/header_actions", user).(:show)
    assert html.has_css?(".f-c-users-header-actions")
  end
end
