# frozen_string_literal: true

require "test_helper"

class Folio::AiTest < ActiveSupport::TestCase
  test "uses configured default provider models" do
    assert_equal "gpt-5.5", Folio::Ai.default_model(:openai)
    assert_equal "claude-opus-4-7", Folio::Ai.default_model(:anthropic)
  end

  test "normalizes provider model config keys" do
    with_ai_config(provider_models: {
      "openai" => "string-key-model",
    }) do
      assert Folio::Ai.known_provider?(:openai)
      assert_equal "string-key-model", Folio::Ai.default_model(:openai)
    end
  end

  test "configures pack-owned options" do
    with_ai_config(enabled: false) do
      Folio::Ai.configure do |config|
        config.enabled = true
      end

      assert_predicate Folio::Ai, :enabled?
    end
  end

  test "disables provider request storage by default" do
    assert_not_predicate Folio::Ai, :provider_request_storage?
  end

  test "uses default text suggestions queue" do
    assert_equal :default, Folio::Ai.text_suggestions_queue
  end

  test "normalizes configured text suggestions queue" do
    with_ai_config(text_suggestions_queue: "critical") do
      assert_equal :critical, Folio::Ai.text_suggestions_queue
    end
  end

  test "is disabled by default" do
    with_ai_config(enabled: false) do
      assert_not Folio::Ai.enabled?
    end
  end

  test "respects global ENV kill switch" do
    original_value = ENV["FOLIO_AI_DISABLED"]
    ENV["FOLIO_AI_DISABLED"] = "1"

    with_ai_config(enabled: true) do
      assert_not Folio::Ai.enabled?
    end
  ensure
    ENV["FOLIO_AI_DISABLED"] = original_value
  end

  test "builds provider adapter with explicit API key" do
    adapter = with_ai_config(provider_request_timeout: 12) do
      Folio::Ai.provider_adapter(provider: :openai, api_key: "secret")
    end

    assert_instance_of Folio::Ai::Providers::OpenAi, adapter
    assert_equal 12, adapter.send(:timeout)
  end

  test "uses prefixed provider API keys" do
    original_openai_value = ENV["FOLIO_AI_OPENAI_API_KEY"]
    original_anthropic_value = ENV["FOLIO_AI_ANTHROPIC_API_KEY"]
    ENV["FOLIO_AI_OPENAI_API_KEY"] = "openai-secret"
    ENV["FOLIO_AI_ANTHROPIC_API_KEY"] = "anthropic-secret"

    assert_equal "openai-secret", Folio::Ai.provider_api_key(:openai)
    assert_equal "anthropic-secret", Folio::Ai.provider_api_key(:anthropic)
  ensure
    restore_env("FOLIO_AI_OPENAI_API_KEY", original_openai_value)
    restore_env("FOLIO_AI_ANTHROPIC_API_KEY", original_anthropic_value)
  end

  test "raises safe error when provider API key is missing" do
    original_prefixed_value = ENV.delete("FOLIO_AI_OPENAI_API_KEY")
    original_legacy_value = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "legacy-secret"

    assert_raises(ArgumentError) do
      Folio::Ai.provider_adapter(provider: :openai)
    end
  ensure
    restore_env("FOLIO_AI_OPENAI_API_KEY", original_prefixed_value)
    restore_env("OPENAI_API_KEY", original_legacy_value)
  end

  test "rejects unknown provider adapter" do
    assert_raises(Folio::Ai::UnknownProviderError) do
      Folio::Ai.provider_adapter_class(:unknown)
    end
  end

  private
    def restore_env(key, value)
      if value
        ENV[key] = value
      else
        ENV.delete(key)
      end
    end
end
