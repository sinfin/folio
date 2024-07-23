# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ScrollListComponentTest < Folio::ComponentTest
  def test_render
    html = [
      '<div class="d-ui-scroll-list__test-item">foo</div>',
      '<div class="d-ui-scroll-list__test-item">bar</div>',
    ]

    render_inline(Dummy::Ui::ScrollListComponent.new(html:))

    assert_selector(".d-ui-scroll-list")
    assert_selector(".d-ui-scroll-list__test-item")
  end
end
