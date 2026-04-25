# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ai::TextSuggestionsComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(component)

    assert_selector(".f-c-ai-text-suggestions")
    assert_selector(".f-c-ai-text-suggestions__button")
    assert_selector("[data-f-c-ai-text-suggestions-endpoint-value='/ai']")
    assert_selector("[data-f-c-ai-text-suggestions-target-selector-value='#article_title']")
    assert_selector("[data-f-c-ai-text-suggestions-copy-button-label-value]")
    assert_selector("[data-f-c-ai-text-suggestions-accept-button-label-value]")
    assert_selector("textarea", text: "Use shorter sentences.", visible: :all)
  end

  def test_does_not_render_when_unavailable
    render_inline(component(available: false))

    assert_no_selector(".f-c-ai-text-suggestions")
  end

  private
    def component(**options)
      Folio::Console::Ai::TextSuggestionsComponent.new(integration_key: :articles,
                                                       field_key: :title,
                                                       endpoint: "/ai",
                                                       target_selector: "#article_title",
                                                       user_instructions: "Use shorter sentences.",
                                                       **options)
    end
end
