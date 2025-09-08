# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::CollapsibleComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::CollapsibleComponent.new(title: "foo")) do
      "bar"
    end

    assert_selector(".f-c-ui-collapsible", text: "foobar")
  end
end
