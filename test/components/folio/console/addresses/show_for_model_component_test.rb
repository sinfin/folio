# frozen_string_literal: true

require "test_helper"

class Folio::Console::Addresses::ShowForModelComponentTest < Folio::Console::ComponentTest
  test "show" do
    user = create(:folio_user)
    render_inline(Folio::Console::Addresses::ShowForModelComponent.new(model: user))
    assert_selector(".f-c-addresses-show-for-model")

    user.create_primary_address!(name: "Mr. Ipsum",
                                 address_line_1: "Foo bar",
                                 address_line_2: "1",
                                 city: "Prague",
                                 zip: "111 11",
                                 country_code: "CZ")
    render_inline(Folio::Console::Addresses::ShowForModelComponent.new(model: user))

    assert_selector(".f-c-addresses-show-for-model")
  end
end
