# frozen_string_literal: true

require "test_helper"

class Folio::Console::Addresses::FieldsComponentTest < Folio::Console::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Console::Addresses::FieldsComponent.new(model:))

    assert_selector(".f-c-addresses-fields")
  end
end
