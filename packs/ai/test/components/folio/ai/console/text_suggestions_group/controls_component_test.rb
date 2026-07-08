# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::TextSuggestionsGroup::ControlsComponentTest < Folio::Console::ComponentTest
  test "renders standalone controls controller and dispatch actions" do
    render_inline(Folio::Ai::Console::TextSuggestionsGroup::ControlsComponent.new)

    assert_selector(".f-ai-c-text-suggestions-group-controls[data-controller='f-ai-c-text-suggestions-group-controls']")
    assert_selector("[data-action*='f-ai-c-text-suggestions-group:state->f-ai-c-text-suggestions-group-controls#onGroupState']")
    assert_selector(".f-ai-c-text-suggestions-group-controls__button",
                    text: I18n.t("folio.ai.console.text_suggestions_group_component.generate_all_label"))
    assert_selector("[data-action='click->f-ai-c-text-suggestions-group-controls#generate']")
    assert_selector("[data-f-ai-c-text-suggestions-group-controls-target='button']")
    assert_selector(".f-ai-c-text-suggestions-group-controls__close")
    assert_selector("[data-action='click->f-ai-c-text-suggestions-group-controls#close']")
    assert_selector("[data-f-ai-c-text-suggestions-group-controls-target='close']")
  end
end
