# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::MenuToolbar::ToolbarComponentTest < Folio::ComponentTest
  def test_render
    create_and_host_site

    with_request_url "/" do
      render_inline(Dummy::Ui::MenuToolbar::ToolbarComponent.new)

      assert_selector(".d-ui-menu-toolbar-toolbar")
    end
  end
end
