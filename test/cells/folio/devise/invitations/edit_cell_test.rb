# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Invitations::EditCellTest < Cell::TestCase
  test "show" do
    create(:folio_site)
    html = cell("folio/devise/invitations/edit",
                resource: Folio::User.new,
                resource_name: :user).(:show)
    assert html.has_css?(".f-devise-invitations-edit")
  end
end
