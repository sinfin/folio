# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Omniauth::IconCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/omniauth/icon", nil).(:show)
    assert html.has_css?(".f-devise-omniauth-icon")

    html = cell("folio/devise/omniauth/icon", :twitter2).(:show)
    assert html.has_css?(".f-devise-omniauth-icon")
  end
end
