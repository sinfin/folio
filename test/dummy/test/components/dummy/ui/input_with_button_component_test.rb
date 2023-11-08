# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::InputWithButtonComponentTest < Folio::ComponentTest
  def test_render
    model = { variant: :primary, label: "test" }
    # TODO: add arguments to test (:f, :attribute, :input_options)

    render_inline(Dummy::Ui::InputWithButtonComponent.new(button_model: model))

    assert_selector(".d-ui-input-with-button")
  end
end
