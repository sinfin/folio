# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Passwords::NewCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/passwords/new",
                resource: Folio::User.new,
                resource_name: :user).(:show)
    assert html.has_css?(".f-devise-passwords-new")
  end
end
