# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::InputWithButtonsCellTest < Folio::Console::CellTest
  test "show" do
    html = cell("folio/console/ui/input_with_buttons", input: "foo", buttons: ["foo"]).(:show)
    assert html.has_css?(".f-c-ui-input-with-buttons")
  end
end
