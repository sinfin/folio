# frozen_string_literal: true

require "test_helper"

class Folio::SpecialCharacters::ListComponentTest < Folio::ComponentTest
  def test_renders_character_grid
    render_inline(Folio::SpecialCharacters::ListComponent.new)

    expected = Folio::SpecialCharacters::ListComponent.character_string.grapheme_clusters
    assert_selector(".f-special-characters-list__char", count: expected.size)
  end
end
