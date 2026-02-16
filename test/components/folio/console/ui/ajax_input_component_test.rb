# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::AjaxInputComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::AjaxInputComponent.new(name: "name",
                                                             url: "#",
                                                             value: "value"))

    assert_selector(".f-c-ui-ajax-input")
  end

  def test_render_with_collection
    render_inline(Folio::Console::Ui::AjaxInputComponent.new(name: "name",
                                                             url: "#",
                                                             value: "a",
                                                             collection: [["Label A", "a"], ["Label B", "b"]]))

    assert_selector(".f-c-ui-ajax-input")
    assert_selector("select.f-c-ui-ajax-input__input")
  end

  def test_input_has_change_action
    render_inline(Folio::Console::Ui::AjaxInputComponent.new(name: "name",
                                                             url: "#",
                                                             value: "value"))

    assert_selector(".f-c-ui-ajax-input__input[data-action*='change->f-c-ui-ajax-input#onChange']")
  end
end
