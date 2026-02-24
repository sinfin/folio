# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::FlagComponentTest < Folio::Console::ComponentTest
  test "render" do
    render_inline(Folio::Console::Ui::FlagComponent.new(locale: :cs))
    assert_equal "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags/4x3/cz.svg",
                 page.find(".f-c-ui-flag__img").native[:src]

    render_inline(Folio::Console::Ui::FlagComponent.new(locale: "CZ"))
    assert_equal "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags/4x3/cz.svg",
                 page.find(".f-c-ui-flag__img").native[:src]

    render_inline(Folio::Console::Ui::FlagComponent.new(locale: "cz"))
    assert_equal "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags/4x3/cz.svg",
                 page.find(".f-c-ui-flag__img").native[:src]
  end
end
