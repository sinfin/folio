# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Providers::OpenAiTest < ActiveSupport::TestCase
  test "builds responses API request" do
    provider = Folio::Ai::Providers::OpenAi.new(api_key: "secret", model: "gpt-5.5")
    field = Folio::Ai::Field.new(key: :title)

    request = provider.build_request(prompt: "Write a title.",
                                     field:,
                                     suggestion_count: 3)

    assert_equal "https://api.openai.com/v1/responses", request.uri.to_s
    assert_equal "Bearer secret", request.headers["Authorization"]
    assert_equal "gpt-5.5", request.body[:model]
    assert_equal "title", request.body.dig(:metadata, :folio_ai_field_key)
    assert_includes request.body[:input].first[:content], "suggestions"
  end

  test "normalizes responses API output text" do
    provider = Folio::Ai::Providers::OpenAi.new(api_key: "secret", model: "gpt-5.5")
    field = Folio::Ai::Field.new(key: :title)
    response_body = {
      output_text: {
        suggestions: [
          { text: "Generated title" },
        ],
      }.to_json,
    }.to_json

    suggestions = provider.normalize_response(response_body:,
                                              field:,
                                              suggestion_count: 3)

    assert_equal ["Generated title"], suggestions.map(&:text)
  end
end
