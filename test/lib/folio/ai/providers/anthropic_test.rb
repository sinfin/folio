# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Providers::AnthropicTest < ActiveSupport::TestCase
  test "builds messages API request" do
    provider = Folio::Ai::Providers::Anthropic.new(api_key: "secret", model: "claude-opus-4-7")
    field = Folio::Ai::Field.new(key: :perex, character_limit: 400)

    request = provider.build_request(prompt: "Write a summary.",
                                     field:,
                                     suggestion_count: 3)

    assert_equal "https://api.anthropic.com/v1/messages", request.uri.to_s
    assert_equal "secret", request.headers["x-api-key"]
    assert_equal "claude-opus-4-7", request.body[:model]
    assert_equal 2_400, request.body[:max_tokens]
    assert_includes request.body[:system], "suggestions"
  end

  test "normalizes messages API text content" do
    provider = Folio::Ai::Providers::Anthropic.new(api_key: "secret", model: "claude-opus-4-7")
    field = Folio::Ai::Field.new(key: :perex)
    response_body = {
      content: [
        {
          type: "text",
          text: {
            suggestions: [
              { text: "Generated summary" },
            ],
          }.to_json,
        },
      ],
    }.to_json

    suggestions = provider.normalize_response(response_body:,
                                              field:,
                                              suggestion_count: 3)

    assert_equal ["Generated summary"], suggestions.map(&:text)
  end
end
