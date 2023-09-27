# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::TabsComponentTest < Folio::Console::ComponentTest
  def test_render
    tabs = [
      { label: "First tab", href: "#1", active: true },
      { label: "Second tab", href: "#2", active: false },
      { label: "Third tab", href: "#3", active: false },
    ]

    render_inline(Folio::Console::Ui::TabsComponent.new(tabs:))

    assert_selector(".f-c-ui-tabs")
  end
end
