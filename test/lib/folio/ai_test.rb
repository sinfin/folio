# frozen_string_literal: true

require "test_helper"

class Folio::AiTest < ActiveSupport::TestCase
  test "uses configured default provider models" do
    assert_equal "gpt-5.5", Folio::Ai.default_model(:openai)
    assert_equal "claude-opus-4-7", Folio::Ai.default_model(:anthropic)
  end

  test "is disabled by default" do
    with_config(folio_ai_enabled: false) do
      assert_not Folio::Ai.enabled?
    end
  end

  test "respects global ENV kill switch" do
    original_value = ENV["FOLIO_AI_DISABLED"]
    ENV["FOLIO_AI_DISABLED"] = "1"

    with_config(folio_ai_enabled: true) do
      assert_not Folio::Ai.enabled?
    end
  ensure
    ENV["FOLIO_AI_DISABLED"] = original_value
  end

  test "builds provider adapter with explicit API key" do
    adapter = Folio::Ai.provider_adapter(provider: :openai, api_key: "secret")

    assert_instance_of Folio::Ai::Providers::OpenAi, adapter
  end

  test "rejects unknown provider adapter" do
    assert_raises(Folio::Ai::UnknownProviderError) do
      Folio::Ai.provider_adapter_class(:unknown)
    end
  end
end
