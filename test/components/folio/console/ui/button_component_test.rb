# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::ButtonComponentTest < Folio::Console::ComponentTest
  def test_anchor
    render_inline(Folio::Console::Ui::ButtonComponent.new(href: "#foo",
                                                          label: "label",
                                                          icon: :send,
                                                          variant: :warning,
                                                          class_name: "my_class"))

    assert_selector(".f-c-ui-button")
  end

  def test_button
    render_inline(Folio::Console::Ui::ButtonComponent.new(type: :submit,
                                                          label: "label",
                                                          icon: :send,
                                                          variant: :warning,
                                                          class_name: "my_class"))

    assert_selector(".f-c-ui-button")
  end
end
