# frozen_string_literal: true

require "test_helper"

class Folio::CookieConsentCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/cookie_consent", "/").(:show)
    assert html
  end
end
