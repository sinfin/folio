# frozen_string_literal: true

require "test_helper"

class Folio::Console::Accounts::InviteAndCopyCellTest < Folio::Console::CellTest
  test "show" do
    skip "TODO: remove with Folio::Accounts"
    model = create(:folio_user, :superadmin)
    html = cell("folio/console/accounts/invite_and_copy", model).(:show)
    assert html.has_css?(".f-c-accounts-invite-and-copy")
  end
end
