# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::BadgeComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::BadgeComponent.new) { "foo" }

    assert_selector(".f-c-ui-badge")
    assert_text("foo")
  end
end
