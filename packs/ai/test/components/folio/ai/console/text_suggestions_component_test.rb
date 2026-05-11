# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::TextSuggestionsComponentTest < Folio::Console::ComponentTest
  test "renders suggestions with input controller actions" do
    render_inline(Folio::Ai::Console::TextSuggestionsComponent.new(result: success_result,
                                                                  component_id: "ai_title",
                                                                  field_label: "Title",
                                                                  show_meta: true))

    assert_selector(".f-ai-c-text-suggestions--open")
    assert_selector("#ai_title.f-ai-c-text-suggestions__panel")
    assert_selector("[data-controller='f-ai-c-text-suggestions']")
    assert_selector("[data-action*='f-ai-c-text-suggestions#accept']", text: "Generated text")
    assert_selector(".f-ai-c-text-suggestions__suggestion-meta", text: "Neutral")
    assert_selector("textarea[data-f-ai-c-text-suggestions-target='instructions']", text: "Shorten it.")
  end

  test "renders error state" do
    render_inline(Folio::Ai::Console::TextSuggestionsComponent.new(result: error_result,
                                                                  component_id: "ai_title",
                                                                  field_label: "Title"))

    assert_selector(".f-ai-c-text-suggestions__panel--error")
    assert_text I18n.t("folio.ai.console.errors.host_ineligible")
    assert_no_selector(".f-ai-c-text-suggestions__suggestion")
  end

  private
    def success_result
      Folio::Ai::SuggestionGenerator::Result.new(success: true,
                                                 suggestions: [
                                                   Folio::Ai::Suggestion.new(key: 1,
                                                                             text: "Generated text",
                                                                             meta: { tone_label: "Neutral" }),
                                                 ],
                                                 field: field,
                                                 user_instruction: "Shorten it.",
                                                 warnings: [])
    end

    def error_result
      Folio::Ai::SuggestionGenerator::Result.new(success: false,
                                                 suggestions: [],
                                                 error_code: :host_ineligible,
                                                 field: field,
                                                 user_instruction: "",
                                                 warnings: [])
    end

    def field
      @field ||= Folio::Ai::Field.new(key: :title,
                                      label: "Title",
                                      input_types: %i[string],
                                      character_limit: 120)
    end
end
