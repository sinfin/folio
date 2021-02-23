# frozen_string_literal: true

require "test_helper"

class Folio::Console::Addresses::ShowForModelCellTest < Folio::Console::CellTest
  test "show" do
    user = create(:folio_user)
    html = cell("folio/console/addresses/show_for_model", user).(:show)
    assert html.has_css?(".f-c-addresses-show-for-model")

    user.create_primary_address!(name: "Mr. Ipsum",
                                 address_line_1: "Foo bar 1",
                                 city: "Prague",
                                 zip: "111 11",
                                 country_code: "CZ")
    html = cell("folio/console/addresses/show_for_model", user).(:show)
    assert html.has_css?(".f-c-addresses-show-for-model")
  end
end
