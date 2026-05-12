# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::TextSuggestionsComponentTest < Folio::Console::ComponentTest
  test "renders suggestions with component controller actions" do
    render_inline(Folio::Ai::Console::TextSuggestionsComponent.new(result: success_result,
                                                                  component_id: "ai_title",
                                                                  field_label: "Title",
                                                                  show_meta: true,
                                                                  integration_key: "articles",
                                                                  field_key: "title"))

    assert_selector("#ai_title.f-ai-c-text-suggestions__panel")
    assert_selector("[data-controller='f-ai-c-text-suggestions']")
    assert_selector("[data-action*='f-ai-input:suggestionStale->f-ai-c-text-suggestions#clearSuggestionSelection']")
    assert_selector("[data-action*='f-ai-input:clientError->f-ai-c-text-suggestions#showClientError']")
    assert_selector("[data-f-ai-c-text-suggestions-integration-key-value='articles']")
    assert_selector("[data-f-ai-c-text-suggestions-field-key-value='title']")
    assert_selector(".f-ai-c-text-suggestions__status[data-f-ai-c-text-suggestions-target='status'][hidden]",
                    visible: :hidden)
    assert_selector("[data-f-ai-c-text-suggestions-target='statusMessage']", visible: :hidden)
    assert_selector("[data-action*='f-ai-c-text-suggestions#accept']", text: "Generated text")
    assert_selector("[data-f-ai-c-text-suggestions-text-param='Generated text']")
    assert_selector("[data-f-ai-c-text-suggestions-key-param='1']")
    assert_selector(".f-ai-c-text-suggestions__suggestion-meta", text: "Neutral")
    assert_selector("textarea[data-f-ai-c-text-suggestions-target='instructions']", text: "Shorten it.")
    assert_no_selector("template[data-f-ai-c-text-suggestions-target='loadingSuggestionsTemplate']",
                       visible: :all)
  end

  test "renders error state" do
    render_inline(Folio::Ai::Console::TextSuggestionsComponent.new(result: error_result,
                                                                  component_id: "ai_title",
                                                                  field_label: "Title"))

    assert_selector(".f-ai-c-text-suggestions__panel--error")
    assert_selector(".f-ai-c-text-suggestions__status:not([hidden])")
    assert_selector("[data-f-ai-c-text-suggestions-target='statusMessage']",
                    text: I18n.t("folio.ai.console.errors.host_ineligible"))
    assert_text I18n.t("folio.ai.console.errors.host_ineligible")
    assert_no_selector(".f-ai-c-text-suggestions__suggestion")
  end

  test "renders loading state with pseudo suggestions" do
    render_inline(Folio::Ai::Console::TextSuggestionsComponent.new(result: loading_result,
                                                                  component_id: "ai_title",
                                                                  field_label: "Title",
                                                                  loading: true))

    assert_no_selector(".f-ai-c-text-suggestions--loading")
    assert_selector(".f-ai-c-text-suggestions__suggestion--loading", count: 3)
    assert_selector(".f-ai-c-text-suggestions__suggestion--loading .f-ai-c-text-suggestions__suggestion-text",
                    text: I18n.t("folio.ai.console.text_suggestions_component.loading_text"),
                    count: 3)
    assert_selector(".f-ai-c-text-suggestions__suggestion-loader.folio-loader", count: 3)
    assert_no_selector(".f-ai-c-text-suggestions__loader")
    assert_selector(".f-ai-c-text-suggestions__status[hidden]", visible: :hidden)
    assert_selector(".f-ai-c-text-suggestions__status svg", visible: :hidden)
    assert_no_selector(".f-ai-c-text-suggestions__panel--error")
    assert_no_selector("[data-f-ai-c-text-suggestions-target='suggestion']")
    assert_selector("textarea[data-f-ai-c-text-suggestions-target='instructions']")
    assert_no_selector("template[data-f-ai-c-text-suggestions-target='loadingSuggestionsTemplate']",
                       visible: :all)
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

    def loading_result
      Folio::Ai::SuggestionGenerator::Result.new(success: true,
                                                 suggestions: [],
                                                 field: field,
                                                 user_instruction: "",
                                                 warnings: [])
    end

    def field
      @field ||= Folio::Ai::Field.new(key: :title,
                                      label: "Title",
                                      character_limit: 120)
    end
end
