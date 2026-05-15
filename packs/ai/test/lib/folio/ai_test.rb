# frozen_string_literal: true

require "test_helper"

class Folio::AiTest < ActiveSupport::TestCase
  test "uses configured default provider models" do
    assert_equal "gpt-5.4-mini", Folio::Ai.default_model(:openai)
    assert_equal "claude-opus-4-7", Folio::Ai.default_model(:anthropic)
  end

  test "keeps premium OpenAI model in built-in model options" do
    options = Folio::Ai.provider_model_options.fetch(:openai)

    assert_equal({ label: "GPT-5.4 mini" }, options.fetch("gpt-5.4-mini"))
    assert_equal({ label: "GPT-5.5", cost_tier: "premium" }, options.fetch("gpt-5.5"))
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
    Folio::Ai.stub(:env_disabled_value, "1") do
      with_ai_config(enabled: true) do
        assert_not Folio::Ai.enabled?
      end
    end
  end

  test "builds provider adapter with explicit API key" do
    adapter = with_ai_config(provider_request_timeout: 12) do
      Folio::Ai.provider_adapter(provider: :openai, api_key: "secret")
    end

    assert_instance_of Folio::Ai::Providers::OpenAi, adapter
    assert_equal 12, adapter.send(:timeout)
  end

  test "uses prefixed provider API keys" do
    Folio::Ai.stub(:provider_api_key_env_values, {
      openai: "openai-secret",
      anthropic: "anthropic-secret",
    }) do
      assert_equal "openai-secret", Folio::Ai.provider_api_key(:openai)
      assert_equal "anthropic-secret", Folio::Ai.provider_api_key(:anthropic)
    end
  end

  test "exposes provider ENV keys" do
    assert_equal "FOLIO_AI_DISABLED", Folio::Ai.env_disabled_key
    assert_equal "FOLIO_AI_OPENAI_API_KEY", Folio::Ai.provider_api_key_env_key(:openai)
    assert_equal "FOLIO_AI_ANTHROPIC_API_KEY", Folio::Ai.provider_api_key_env_key(:anthropic)
    assert_equal "FOLIO_AI_OPENAI_MODELS", Folio::Ai.provider_models_env_key(:openai)
  end

  test "filters eligible providers by required credentials" do
    Folio::Ai.stub(:provider_api_key_env_values, { anthropic: "anthropic-secret" }) do
      assert_not Folio::Ai.eligible_provider?(:openai)
      assert Folio::Ai.eligible_provider?(:anthropic)
      assert_equal({ anthropic: "claude-opus-4-7" }, Folio::Ai.eligible_provider_models)
    end
  end

  test "treats configured custom providers as eligible" do
    with_ai_config(provider_models: { demo: "demo" }) do
      assert Folio::Ai.eligible_provider?(:demo)
      assert_equal({ demo: "demo" }, Folio::Ai.eligible_provider_models)
      assert_nil Folio::Ai.provider_api_key(:demo)
    end
  end

  test "raises safe error when provider API key is missing" do
    Folio::Ai.stub(:provider_api_key_env_values, {}) do
      assert_raises(ArgumentError) do
        Folio::Ai.provider_adapter(provider: :openai)
      end
    end
  end

  test "rejects unknown provider adapter" do
    assert_raises(Folio::Ai::UnknownProviderError) do
      Folio::Ai.provider_adapter_class(:unknown)
    end
  end
end
