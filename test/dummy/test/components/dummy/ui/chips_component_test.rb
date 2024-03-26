# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ChipsComponentTest < Folio::ComponentTest
  def test_render
    links = [{ label: "foo", href: "foo" }]

    render_inline(Dummy::Ui::ChipsComponent.new(links:))

    assert_selector(".d-ui-chips")
  end
end
