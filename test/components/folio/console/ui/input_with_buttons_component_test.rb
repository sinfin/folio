# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::InputWithButtonsComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::InputWithButtonsComponent.new(input: "foo",
                                                                    buttons_kwargs: [{ type: :submit }]))

    assert_selector(".f-c-ui-input-with-buttons")
  end
end
