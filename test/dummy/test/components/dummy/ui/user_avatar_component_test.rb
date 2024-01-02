# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::UserAvatarComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Dummy::Ui::UserAvatarComponent.new)

    assert_selector(".d-ui-user-avatar")
  end
end
