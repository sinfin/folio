# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::FlagCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/ui/flag", :cs).(:show)
    assert_equal "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags/4x3/cz.svg",
                 html.find(".f-c-ui-flag__img").native[:src]

    html = cell("folio/console/ui/flag", "CZ").(:show)
    assert_equal "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags/4x3/cz.svg",
                 html.find(".f-c-ui-flag__img").native[:src]

    html = cell("folio/console/ui/flag", "cz").(:show)
    assert_equal "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags/4x3/cz.svg",
                 html.find(".f-c-ui-flag__img").native[:src]
  end
end
