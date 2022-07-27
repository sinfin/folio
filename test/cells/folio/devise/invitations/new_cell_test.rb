# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Invitations::NewCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/invitations/new",
                resource: Folio::User.new,
                resource_name: :user).(:show)
    assert html.has_css?(".f-devise-invitations-new")
  end
end
