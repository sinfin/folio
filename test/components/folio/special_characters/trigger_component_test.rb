# frozen_string_literal: true

require "test_helper"

class Folio::SpecialCharacters::TriggerComponentTest < Folio::ComponentTest
  def test_renders_trigger_button
    render_inline(Folio::SpecialCharacters::TriggerComponent.new)

    assert_selector(".f-special-characters-trigger")
    assert_selector("[data-test-id='special-characters-trigger']")
    assert_text "Ø"
  end
end
