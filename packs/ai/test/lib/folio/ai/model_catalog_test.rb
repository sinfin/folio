# frozen_string_literal: true

require "test_helper"

class Folio::Ai::ModelCatalogTest < ActiveSupport::TestCase
  CACHE_KEY = "folio/ai/model_catalog/v1/openai"

  setup do
    Rails.cache.delete(CACHE_KEY)
  end

  teardown do
    Rails.cache.delete(CACHE_KEY)
  end

  test "fetches provider models and caches them" do
    stub_request(:get, "https://api.openai.com/v1/models")
      .to_return(body: {
        data: [
          { id: "gpt-5.5", created: 1 },
        ],
      }.to_json)

    catalog = Folio::Ai::ModelCatalog.new(provider: :openai, api_key: "secret")

    with_config(folio_ai_provider_model_options: {
      openai: {
        "gpt-5.5" => { label: "GPT 5.5", cost_tier: "premium" },
      },
    }) do
      first_result = catalog.result(selected: "retired-model")
      second_result = catalog.result

      assert first_result.verified?
      assert second_result.verified?
      assert_equal ["gpt-5.5", "retired-model"], first_result.models.map(&:id)
      assert_equal "GPT 5.5 - Premium - gpt-5.5", first_result.models.first.select_label
      assert_not first_result.models.last.available?
    end

    assert_requested :get, "https://api.openai.com/v1/models", times: 1
  end

  test "falls back to configured models when provider list is unavailable" do
    stub_request(:get, "https://api.openai.com/v1/models").to_timeout

    catalog = Folio::Ai::ModelCatalog.new(provider: :openai, api_key: "secret")

    with_config(folio_ai_provider_model_options: {
      openai: {
        "gpt-5.5" => { label: "GPT 5.5", cost_tier: "premium" },
      },
    }) do
      result = catalog.result

      assert_not result.verified?
      assert_equal ["gpt-5.5"], result.models.map(&:id)
      assert result.models.first.available?
    end
  end

  test "returns verified unavailable status when selected model is missing from provider list" do
    stub_request(:get, "https://api.openai.com/v1/models")
      .to_return(body: {
        data: [
          { id: "gpt-5.5", created: 1 },
        ],
      }.to_json)

    status = Folio::Ai::ModelCatalog.new(provider: :openai,
                                         api_key: "secret").status("retired-model")

    assert status.verified?
    assert status.unavailable?
  end
end
