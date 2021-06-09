# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Confirmations::NewCellTest < Cell::TestCase
  test "show" do
    skip unless ::Rails.application.config.folio_users_confirmable

    html = cell("folio/devise/confirmations/new",
                resource: Folio::User.new,
                resource_name: :user).(:show)

    assert html.has_css?(".f-devise-confirmations-new")
  end
end
