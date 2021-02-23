# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Passwords::EditCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/passwords/edit",
                resource: Folio::User.new,
                resource_name: :user).(:show)
    assert html.has_css?(".f-devise-passwords-edit")
  end
end
