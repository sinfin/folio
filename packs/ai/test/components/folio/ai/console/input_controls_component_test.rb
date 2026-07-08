# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::Console::InputControlsComponentTest < Folio::Console::ComponentTest
  test "renders input controls and suggestion mount" do
    render_inline(Folio::Ai::Console::InputControlsComponent.new(component_id: "ai_title",
                                                                 label: "Suggest",
                                                                 undo_label: "Undo"))

    assert_selector(".f-ai-c-input-controls[data-controller='f-ai-c-input-controls']")
    assert_selector(".f-ai-input__button[aria-controls='ai_title']", text: "Suggest")
    assert_selector(".f-ai-input__button[data-action='click->f-ai-c-input-controls#toggle']")
    assert_selector(".f-ai-input__button svg", count: 1)
    assert_selector(".f-ai-input__undo[hidden][data-action='click->f-ai-c-input-controls#undo']",
                    text: "Undo",
                    visible: :all)
    assert_selector(".f-ai-input__custom-html[data-f-ai-c-input-controls-target='customHtml']")
  end
end
