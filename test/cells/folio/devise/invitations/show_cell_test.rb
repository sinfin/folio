# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Invitations::ShowCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/invitations/show",
                "foo@bar.baz").(:show)
    assert html.has_css?(".f-devise-invitations-show")
  end
end
