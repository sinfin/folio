# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Invitations::ShowCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/invitations/show",
                email: "foo@bar.baz",
                resource: Folio::User.new,
                resource_name: :user).(:show)
    assert html.has_css?(".f-devise-invitations-show")
  end
end
