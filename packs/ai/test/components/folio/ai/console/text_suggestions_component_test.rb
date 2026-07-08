# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::Console::TextSuggestionsComponentTest < Folio::Console::ComponentTest
  test "renders suggestions" do
    I18n.with_locale(:en) do
      render_inline(component)
    end

    assert_selector(".f-ai-c-text-suggestions")
    assert_selector(".f-ai-c-text-suggestions__panel")
    assert_selector(".f-ai-c-text-suggestions__close")
    assert_selector(".f-ai-c-text-suggestions__suggestion", count: 2)
    assert_selector(".f-ai-c-text-suggestions__suggestions")
    assert_selector(".f-ai-c-text-suggestions__suggestion-accept")
    assert_text "First title"
    assert_no_selector(".f-ai-c-text-suggestions__suggestion-meta")
    assert_no_text "12 characters"
    assert_no_text "> 10"
    assert_selector("textarea", text: "Use short words.")
    assert_selector(".f-ai-c-text-suggestions__regenerate")
  end

  test "renders loading state" do
    I18n.with_locale(:en) do
      render_inline(component(suggestions: [], loading: true))
    end

    assert_selector(".f-ai-c-text-suggestions__suggestion--loading", count: 3)
    assert_text "Preparing suggestions"
  end

  test "renders error state without instructions" do
    I18n.with_locale(:en) do
      render_inline(component(suggestions: [], error_code: :provider_unavailable))
    end

    assert_text "Configure an AI provider before using AI suggestions."
    assert_no_selector(".f-ai-c-text-suggestions__instructions")
  end

  test "renders czech labels" do
    I18n.with_locale(:cs) do
      render_inline(component)
    end

    assert_selector(".f-ai-c-text-suggestions__close[aria-label='Zavřít']")
    assert_selector(".f-ai-c-text-suggestions__regenerate", text: "Uložit vlastní instrukce")
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
