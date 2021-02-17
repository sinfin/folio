# frozen_string_literal: true

require "test_helper"

class Folio::Devise::OmniauthCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/omniauth", nil).(:show)
    assert html.has_css?(".f-devise-omniauth")
  end
end
