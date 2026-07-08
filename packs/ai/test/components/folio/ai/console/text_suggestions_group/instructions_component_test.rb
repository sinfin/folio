# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::TextSuggestionsGroup::InstructionsComponentTest < Folio::Console::ComponentTest
  test "renders standalone instructions controller and regenerate action" do
    render_inline(Folio::Ai::Console::TextSuggestionsGroup::InstructionsComponent.new(stored_instruction: "Keep it short."))

    assert_selector(".f-ai-c-text-suggestions-group-instructions[data-controller='f-ai-c-text-suggestions-group-instructions']")
    assert_selector("[data-action*='f-ai-c-text-suggestions-group:state->f-ai-c-text-suggestions-group-instructions#onGroupState']")
    assert_selector("textarea.f-ai-c-text-suggestions-group-instructions__input",
                    text: "Keep it short.")
    assert_selector("textarea[data-controller='f-input-autosize']")
    assert_selector("textarea[data-f-ai-c-text-suggestions-group-instructions-target='instructions']")
    assert_selector("[data-action='click->f-ai-c-text-suggestions-group-instructions#regenerate']",
                    text: I18n.t("folio.ai.console.text_suggestions_group_component.regenerate_all_label"))
    assert_selector("[data-f-ai-c-text-suggestions-group-instructions-target='regenerate']")
  end
end
