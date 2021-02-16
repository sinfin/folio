# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Registrations::EditCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/registrations/edit",
                resource: Folio::User.new,
                resource_name: :user).(:show)
    assert html.has_css?(".f-devise-registrations-edit")
  end
end
