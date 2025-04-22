# frozen_string_literal: true

require "test_helper"

class Folio::Console::CurrentUsers::ShowComponentTest < Folio::Console::ComponentTest
  def test_render
    user = create(:folio_user)

    render_inline(Folio::Console::CurrentUsers::ShowComponent.new(user:))

    assert_selector(".f-c-current-users-show")
  end
end
