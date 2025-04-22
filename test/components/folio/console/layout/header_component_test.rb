# frozen_string_literal: true

require "test_helper"

class Folio::Console::Layout::HeaderComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Layout::HeaderComponent.new)

    assert_selector(".f-c-layout-header")
    assert_no_selector(".f-c-layout-header__sign-out-link")
  end

  def test_render_with_user
    Folio::Current.user = create(:folio_user)
    render_inline(Folio::Console::Layout::HeaderComponent.new)

    assert_selector(".f-c-layout-header")
    assert_selector(".f-c-layout-header__sign-out-link")
  end
end
