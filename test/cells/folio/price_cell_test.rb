# frozen_string_literal: true

require "test_helper"

class Folio::PriceCellTest < Cell::TestCase
  test "show" do
    I18n.with_locale(:cs) do
      assert_equal("3 Kč", cell("folio/price", 3).(:show).text)
      assert_equal("1 500 Kč", cell("folio/price", 1500).(:show).text)
      assert_equal("-4 000 Kč", cell("folio/price", -4000).(:show).text)
      assert_equal("-4 000 EUR", cell("folio/price", -4000, currency: "EUR").(:show).text)
      assert_equal("0 EUR", cell("folio/price", 0, currency: "EUR").(:show).text)
      assert_equal("Zdarma", cell("folio/price", 0, currency: "EUR", zero_as_text: true).(:show).text)
    end
  end
end
