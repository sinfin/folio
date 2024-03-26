# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::BooleanToggleComponentTest < Folio::ComponentTest
  def test_render
    record = create(:folio_page, published: true)

    render_inline(Dummy::Ui::BooleanToggleComponent.new(record:, attribute: :published, url: "#"))

    assert_selector(".d-ui-boolean-toggle")
  end
end
