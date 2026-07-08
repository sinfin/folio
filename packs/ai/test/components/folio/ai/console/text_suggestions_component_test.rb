# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::Console::TextSuggestionsComponentTest < Folio::Console::ComponentTest
  test "renders suggestions" do
    render_inline(component)

    assert_selector(".f-ai-c-text-suggestions")
    assert_selector(".f-ai-c-text-suggestions__panel")
    assert_selector(".f-ai-c-text-suggestions__close")
    assert_selector(".f-ai-c-text-suggestions__suggestion", count: 2)
    assert_selector(".f-ai-c-text-suggestions__suggestions")
    assert_selector(".f-ai-c-text-suggestions__suggestion-accept")
    assert_text "First title"
    assert_text "12 characters"
    assert_text "> 10"
    assert_selector("textarea", text: "Use short words.")
    assert_selector(".f-ai-c-text-suggestions__regenerate")
  end

  test "renders loading state" do
    render_inline(component(suggestions: [], loading: true))

    assert_selector(".f-ai-c-text-suggestions__suggestion--loading", count: 3)
    assert_text "Preparing suggestions"
  end

  test "renders error state without instructions" do
    render_inline(component(suggestions: [], error_code: :provider_unavailable))

    assert_text "AI suggestions could not be generated."
    assert_no_selector(".f-ai-c-text-suggestions__instructions")
  end

  private
    def component(**kwargs)
      Folio::Ai::Console::TextSuggestionsComponent.new(
        component_id: "ai_title",
        field: {
          key: "title",
          label: "Title",
        },
        suggestions: [
          {
            key: 1,
            text: "First title",
            character_count: 12,
            character_limit: 10,
            over_character_limit: true,
          },
          {
            key: 2,
            text: "Second title",
            character_count: 12,
          },
        ],
        instructions: "Use short words.",
        **kwargs
      )
    end
end
