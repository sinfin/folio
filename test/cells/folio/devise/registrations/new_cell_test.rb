# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Registrations::NewCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/registrations/new",
                resource: Folio::User.new,
                resource_name: :user).(:show)
    assert html.has_css?(".f-devise-registrations-new")
  end
end
