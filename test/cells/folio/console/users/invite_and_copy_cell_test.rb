# frozen_string_literal: true

require "test_helper"

class Folio::Console::Users::InviteAndCopyCellTest < Folio::Console::CellTest
  test "show" do
    skip "TODO: remove with Folio::Users"
    model = create(:folio_user, :superadmin)
    html = cell("folio/console/users/invite_and_copy", model).(:show)
    assert html.has_css?(".f-c-users-invite-and-copy")
  end
end
