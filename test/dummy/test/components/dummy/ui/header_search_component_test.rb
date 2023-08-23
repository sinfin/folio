# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::HeaderSearchComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::HeaderSearchComponent.new)

    assert_selector(".d-ui-header-search")
  end
end
