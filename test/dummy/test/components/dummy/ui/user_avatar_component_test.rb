# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::UserAvatarComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::UserAvatarComponent.new)

    assert_selector(".d-ui-user-avatar")
  end
end
