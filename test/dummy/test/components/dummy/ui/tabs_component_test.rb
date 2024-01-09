# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::TabsComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::TabsComponent.new(tabs: nil))
    assert_no_selector(".d-ui-tabs")

    tabs = [
      { href: "#", active: true, label: "Current tab" },
      { href: "#", label: "Another tab" },
      { href: "#", label: "Another tab" },
    ]

    render_inline(Dummy::Ui::TabsComponent.new(tabs:))
    assert_selector(".d-ui-tabs")
  end
end
