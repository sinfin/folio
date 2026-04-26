# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Providers::BaseTest < ActiveSupport::TestCase
  ENDPOINT = "https://provider.example.test/v1/messages"

  class TestProvider < Folio::Ai::Providers::Base
    def build_request(prompt:, field:, suggestion_count:)
      Request.new(uri: URI(Folio::Ai::Providers::BaseTest::ENDPOINT),
                  headers: { "Content-Type" => "application/json" },
                  body: { prompt:, field: field.key, suggestion_count: })
    end
  end

  setup do
    @provider = TestProvider.new(api_key: "secret", model: "test-model", timeout: 1)
    @field = Folio::Ai::Field.new(key: :title)
  end

  test "maps provider timeout to typed error" do
    stub_request(:post, ENDPOINT).to_timeout

    assert_raises(Folio::Ai::ProviderTimeoutError) do
      @provider.generate_suggestions(prompt: "Write a title.",
                                     field: @field,
                                     suggestion_count: 1)
    end
  end

  test "maps transport failure to provider error" do
    stub_request(:post, ENDPOINT).to_raise(SocketError.new("offline"))

    assert_raises(Folio::Ai::ProviderError) do
      @provider.generate_suggestions(prompt: "Write a title.",
                                     field: @field,
                                     suggestion_count: 1)
    end
  end

  test "maps missing model response to typed error" do
    stub_request(:post, ENDPOINT).to_return(status: 404,
                                           body: {
                                             error: {
                                               code: "model_not_found",
                                               message: "The model does not exist.",
                                             },
                                           }.to_json)

    assert_raises(Folio::Ai::ProviderModelUnavailableError) do
      @provider.generate_suggestions(prompt: "Write a title.",
                                     field: @field,
                                     suggestion_count: 1)
    end
  end
end
