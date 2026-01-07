# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::FlagComponentTest < Folio::Console::ComponentTest
  test "show" do
    render_inline(Folio::Console::Ui::FlagComponent.new(code: :cs))
    assert_selector(".f-c-ui-flag__img[src='https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags/4x3/cz.svg']")

    render_inline(Folio::Console::Ui::FlagComponent.new(code: "CZ"))
    assert_selector(".f-c-ui-flag__img[src='https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags/4x3/cz.svg']")

    render_inline(Folio::Console::Ui::FlagComponent.new(code: "cz"))
    assert_selector(".f-c-ui-flag__img[src='https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags/4x3/cz.svg']")
  end
end
