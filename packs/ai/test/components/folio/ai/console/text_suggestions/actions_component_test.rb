# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::TextSuggestions::ActionsComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(component)

    assert_selector(".f-ai-c-text-suggestions__actions[data-controller='f-ai-c-text-suggestions-actions']")
    assert_selector("[data-f-ai-c-text-suggestions-actions-component-id-value='ai_title']")
    assert_selector("[data-action*='f-ai-c-text-suggestions:state@document->f-ai-c-text-suggestions-actions#onState']")
    assert_selector("#ai_title_button[aria-controls='ai_title'][aria-expanded='false']")
    assert_selector("#ai_title_button[data-action='click->f-ai-c-text-suggestions-actions#toggle']")
    assert_selector("#ai_title_button[data-f-ai-c-text-suggestions-actions-target='button']")
    assert_selector(".f-ai-c-text-suggestions__spark svg")
    assert_selector("#ai_title_undo[hidden]", visible: :all)
    assert_selector("#ai_title_undo[data-action='click->f-ai-c-text-suggestions-actions#undo']", visible: :all)
    assert_selector("#ai_title_undo[data-f-ai-c-text-suggestions-actions-target='undoButton']", visible: :all)
    assert_selector(".f-ai-c-text-suggestions__undo-icon svg", visible: :all)
  end

  def test_render_external
    render_inline(component(external: true))

    assert_selector(".f-ai-c-text-suggestions.f-ai-c-text-suggestions__actions.f-ai-c-text-suggestions--external-actions")
    assert_selector("[data-controller='f-ai-c-text-suggestions-actions']")
    assert_selector("#ai_title_button")
    assert_selector("#ai_title_undo", visible: :all)
  end

  private
    def component(**options)
      Folio::Ai::Console::TextSuggestions::ActionsComponent.new(component_id: "ai_title",
                                                                **options)
  end
end
