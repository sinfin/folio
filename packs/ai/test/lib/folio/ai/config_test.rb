# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::ConfigTest < ActiveSupport::TestCase
  test "defaults to enabled OpenAI configuration" do
    Folio::Ai.stub(:disabled_by_env?, false) do
      config = Folio::Ai::Config.new

      assert_predicate config, :enabled?
      assert_equal :openai, config.default_provider
      assert_equal Folio::Ai::DEFAULT_OPENAI_MODEL, config.default_model(:openai)
      assert_equal :default, config.text_suggestions_queue
      assert_equal 45_000, config.client_request_timeout_ms
    end
  end

  test "defaults to disabled when the kill switch is set" do
    Folio::Ai.stub(:disabled_by_env?, true) do
      assert_not_predicate Folio::Ai::Config.new, :enabled?
    end
  end

  test "normalizes queue and timeout" do
    config = Folio::Ai::Config.new(text_suggestions_queue: "critical",
                                   client_request_timeout_ms: 12_000)

    assert config.known_provider?(:dummy)
    assert_not config.known_provider?(:unknown)
    assert_equal :critical, config.text_suggestions_queue
    assert_equal 12_000, config.client_request_timeout_ms
  end
end
