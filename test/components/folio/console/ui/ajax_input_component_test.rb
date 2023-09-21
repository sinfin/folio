# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::AjaxInputComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::AjaxInputComponent.new(name: "name",
                                                             url: "#",
                                                             value: "value"))

    assert_selector(".f-c-ui-ajax-input")
  end
end
