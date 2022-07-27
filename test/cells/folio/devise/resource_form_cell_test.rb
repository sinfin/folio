# frozen_string_literal: true

require "test_helper"

class Folio::Devise::ResourceFormCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/resource_form",
                resource: Folio::User.new,
                resource_name: :user,
                form_url: "/").(:show)
    assert html.has_css?(".f-devise-resource-form")
  end
end
