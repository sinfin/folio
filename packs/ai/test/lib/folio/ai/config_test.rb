# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::ConfigTest < ActiveSupport::TestCase
  test "defaults to enabled OpenAI configuration" do
    Folio::Ai.stub(:disabled_by_env?, false) do
      config = Folio::Ai::Config.new

      assert_predicate config, :enabled?
      assert_equal :openai, config.default_provider
      assert_equal({ openai: Folio::Ai::DEFAULT_OPENAI_MODEL }, config.provider_models)
      assert_equal :default, config.text_suggestions_queue
      assert_equal 45_000, config.client_request_timeout_ms
    end
  end

  test "defaults to disabled when the kill switch is set" do
    Folio::Ai.stub(:disabled_by_env?, true) do
      assert_not_predicate Folio::Ai::Config.new, :enabled?
    end
  end

  test "normalizes configured providers and queue" do
    config = Folio::Ai::Config.new(provider_models: { "dummy" => "dummy-model" },
                                   text_suggestions_queue: "critical",
                                   client_request_timeout_ms: 12_000)

    assert_equal({ dummy: "dummy-model" }, config.provider_models)
    assert_equal "dummy-model", config.default_model(:dummy)
    assert config.known_provider?(:dummy)
    assert_equal :critical, config.text_suggestions_queue
    assert_equal 12_000, config.client_request_timeout_ms
  end
end
