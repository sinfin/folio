# frozen_string_literal: true

require "test_helper"

class Folio::Devise::OmniauthConflictCellTest < Cell::TestCase
  test "show" do
    auth = create_omniauth_authentication
    html = cell("folio/devise/omniauth_conflict", auth).(:show)
    assert html.has_css?(".f-devise-omniauth-conflict")
  end
end
