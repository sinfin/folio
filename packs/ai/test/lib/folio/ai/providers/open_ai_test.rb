# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::Providers::OpenAiTest < ActiveSupport::TestCase
  test "posts prompt to the Responses API" do
    captured_body = nil

    stub_request(:post, Folio::Ai::Providers::OpenAi::ENDPOINT)
      .with(headers: { "Authorization" => "Bearer secret" }) do |request|
        captured_body = JSON.parse(request.body)
      end
      .to_return(body: { output_text: "Generated title" }.to_json)

    provider = Folio::Ai::Providers::OpenAi.new(api_key: "secret", model: "gpt-test")

    assert_equal "Generated title", provider.complete(prompt: "Write a title.", suggestion_count: 3)
    assert_equal "gpt-test", captured_body["model"]
    assert_equal false, captured_body["store"]
    assert_equal "system", captured_body.dig("input", 0, "role")
    assert_equal "user", captured_body.dig("input", 1, "role")
    assert_equal "Write a title.", captured_body.dig("input", 1, "content")
  end

  test "extracts message output text" do
    stub_request(:post, Folio::Ai::Providers::OpenAi::ENDPOINT)
      .to_return(body: {
        output: [
          {
            type: "message",
            content: [
              { type: "output_text", text: "Generated perex" },
            ],
          },
        ],
      }.to_json)

    provider = Folio::Ai::Providers::OpenAi.new(api_key: "secret", model: "gpt-test")

    assert_equal "Generated perex", provider.complete(prompt: "Write a perex.", suggestion_count: 3)
  end

  test "requires an API key" do
    assert_raises(Folio::Ai::ProviderError) do
      Folio::Ai::Providers::OpenAi.new(api_key: nil)
    end
  end

  test "raises provider error for failed requests" do
    stub_request(:post, Folio::Ai::Providers::OpenAi::ENDPOINT)
      .to_return(status: 401, body: { error: { message: "Unauthorized" } }.to_json)

    provider = Folio::Ai::Providers::OpenAi.new(api_key: "secret", model: "gpt-test")

    assert_raises(Folio::Ai::ProviderError) do
      provider.complete(prompt: "Write a title.")
    end
  end
end
