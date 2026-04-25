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

  test "normalizes responses API message output after reasoning items" do
    provider = Folio::Ai::Providers::OpenAi.new(api_key: "secret", model: "gpt-5.5")
    field = Folio::Ai::Field.new(key: :title)
    response_body = {
      output: [
        {
          type: "reasoning",
          summary: [],
        },
        {
          type: "message",
          content: [
            {
              type: "output_text",
              text: {
                suggestions: [
                  { text: "Generated title" },
                ],
              }.to_json,
            },
          ],
        },
      ],
    }.to_json

    suggestions = provider.normalize_response(response_body:,
                                              field:,
                                              suggestion_count: 3)

    assert_equal ["Generated title"], suggestions.map(&:text)
  end

  test "generates suggestions through responses API with VCR" do
    cassette = "folio/ai/providers/open_ai/generate_suggestions"
    skip_without_openai_key_or_cassette(cassette)

    provider = Folio::Ai::Providers::OpenAi.new(api_key: ENV.fetch("OPENAI_API_KEY", "recorded-openai-key"),
                                                model: ENV.fetch("OPENAI_MODEL", Folio::Ai::DEFAULT_OPENAI_MODEL),
                                                timeout: 60)
    field = Folio::Ai::Field.new(key: :title, character_limit: 80)
    prompt = <<~TEXT.squish
      Create one concise Czech news headline for an article about safe AI prompt
      management in a CMS. Return the text in Czech.
    TEXT

    VCR.use_cassette(cassette) do
      suggestions = provider.generate_suggestions(prompt:, field:, suggestion_count: 1)

      assert_equal 1, suggestions.size
      assert_predicate suggestions.first.text, :present?
    end
  end

  private
    def skip_without_openai_key_or_cassette(cassette)
      return if ENV["OPENAI_API_KEY"].present?
      return if File.exist?(File.join("test/fixtures/vcr_cassettes", "#{cassette}.yml"))

      skip "Set OPENAI_API_KEY to record this VCR cassette."
    end
end
