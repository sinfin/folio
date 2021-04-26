# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Sessions::NewCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/sessions/new",
                resource: Folio::User.new,
                resource_name: :user).(:show)
    assert html.has_css?(".f-devise-sessions-new")
  end
end
