# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::TextSuggestionsComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(component)

    assert_selector(".f-ai-c-text-suggestions")
    assert_selector(".f-ai-c-text-suggestions__button")
    assert_selector(".f-ai-c-text-suggestions__spark svg")
    assert_selector(".f-ai-c-text-suggestions__undo-icon svg", visible: :all)
    assert_selector("[data-controller='f-ai-c-text-suggestions']")
    assert_selector("[data-f-ai-c-text-suggestions-endpoint-value='/ai']")
    assert_selector("[data-f-ai-c-text-suggestions-target-selector-value='#article_title']")
    assert_selector("[data-f-ai-c-text-suggestions-current-state-policy-value='persisted_record']")
    assert_selector("[data-f-ai-c-text-suggestions-request-timeout-ms-value='45000']")
    assert_selector("[data-f-ai-c-text-suggestions-open-class='f-ai-c-text-suggestions--open']")
    assert_selector("[data-f-ai-c-text-suggestions-loading-class='f-ai-c-text-suggestions--loading']")
    assert_selector("[data-f-ai-c-text-suggestions-request-timeout-text-value]")
    assert_selector("[data-f-ai-c-text-suggestions-copy-button-label-value]")
    assert_selector("[data-f-ai-c-text-suggestions-accept-button-label-value]")
    assert_selector("textarea", text: "Use shorter sentences.", visible: :all)
  end

  def test_does_not_render_when_unavailable
    render_inline(component(available: false))

    assert_no_selector(".f-ai-c-text-suggestions")
  end

  def test_render_with_external_controls
    render_inline(component(id: "ai_title",
                            external_controls: true,
                            external_button_selector: "#ai_title_button",
                            external_undo_selector: "#ai_title_undo"))

    assert_selector("#ai_title.f-ai-c-text-suggestions--external-controls")
    assert_selector("[data-f-ai-c-text-suggestions-external-button-selector-value='#ai_title_button']")
    assert_selector("[data-f-ai-c-text-suggestions-external-undo-selector-value='#ai_title_undo']")
  end

  def test_render_with_current_form_snapshot_policy
    render_inline(component(current_state_policy: :current_form_snapshot))

    assert_selector("[data-f-ai-c-text-suggestions-current-state-policy-value='current_form_snapshot']")
  end

  private
    def component(**options)
      Folio::Ai::Console::TextSuggestionsComponent.new(integration_key: :articles,
                                                       field_key: :title,
                                                       endpoint: "/ai",
                                                       target_selector: "#article_title",
                                                       user_instructions: "Use shorter sentences.",
                                                       **options)
    end
end
