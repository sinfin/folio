# frozen_string_literal: true

require "test_helper"

class Folio::Console::Accounts::InviteAndCopyCellTest < Folio::Console::CellTest
  test "show" do
    model = create(:folio_admin_account)
    html = cell("folio/console/accounts/invite_and_copy", model).(:show)
    assert html.has_css?(".f-c-accounts-invite-and-copy")
  end
end
