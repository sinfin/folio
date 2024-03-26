# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ModalComponentTest < Folio::ComponentTest
  def test_render
    class_name = "hello"

    render_inline(Dummy::Ui::ModalComponent.new(class_name:))

    assert_selector(".d-ui-modal")
    assert_selector(".hello")
  end
end
