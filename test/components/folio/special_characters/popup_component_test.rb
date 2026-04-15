# frozen_string_literal: true

require "test_helper"

class Folio::SpecialCharacters::PopupComponentTest < Folio::ComponentTest
  def test_renders_popup_with_grid
    render_inline(Folio::SpecialCharacters::PopupComponent.new)

    assert_selector(".f-special-characters-popup")
    assert_selector(".f-special-characters-popup__header")
    assert_selector(".f-special-characters-popup__close")
    assert_selector(".f-special-characters-list")
  end
end
