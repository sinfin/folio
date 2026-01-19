# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::MenuToolbar::DropdownComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::MenuToolbar::DropdownComponent.new(type: :user_menu))

    assert_selector(".d-ui-menu-toolbar-dropdown")
  end
end
