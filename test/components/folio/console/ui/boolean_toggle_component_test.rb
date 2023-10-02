# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::BooleanToggleComponentTest < Folio::Console::ComponentTest
  def test_render
    record = create(:folio_page, published: true)

    render_inline(Folio::Console::Ui::BooleanToggleComponent.new(record:, attribute: :published, url: "#"))

    assert_selector(".f-c-ui-boolean-toggle")
  end
end
