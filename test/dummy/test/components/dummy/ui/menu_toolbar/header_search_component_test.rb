# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::MenuToolbar::HeaderSearchComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::MenuToolbar::HeaderSearchComponent.new)

    assert_selector(".d-ui-menu-toolbar-header-search")
  end
end
