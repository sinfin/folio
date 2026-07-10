# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::ProvidersTest < ActiveSupport::TestCase
  test "offers dummy provider only in development" do
    Rails.stub(:env, ActiveSupport::StringInquirer.new("development")) do
      assert_predicate Folio::Ai::Providers::Dummy, :available?
    end

    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      assert_not_predicate Folio::Ai::Providers::Dummy, :available?
    end
  end

  test "offers OpenAI provider only with API key" do
    Folio::Ai.stub(:openai_api_key, "secret") do
      assert_predicate Folio::Ai::Providers::OpenAi, :available?
    end

    Folio::Ai.stub(:openai_api_key, nil) do
      assert_not_predicate Folio::Ai::Providers::OpenAi, :available?
    end
  end

  test "defines dummy model options" do
    assert_equal [Folio::Ai::Providers::Dummy::DEFAULT_MODEL], Folio::Ai::Providers::Dummy.models
    assert_equal Folio::Ai::Providers::Dummy::DEFAULT_MODEL, Folio::Ai::Providers::Dummy.default_model
  end

  test "delays dummy responses only in development" do
    Rails.stub(:env, ActiveSupport::StringInquirer.new("development")) do
      assert_equal 1.second, Folio::Ai::Providers::Dummy.response_delay
    end

    Rails.stub(:env, ActiveSupport::StringInquirer.new("test")) do
      assert_equal 0, Folio::Ai::Providers::Dummy.response_delay
    end
  end

  test "returns field-aware dummy suggestions without prompt text" do
    prompt = <<~TEXT.squish
      Generate suggestions.
      #{Folio::Ai::TextSuggestionGenerator::CONTEXT_MARKER}
      {"field":{"key":"perex"}}
    TEXT

    response = JSON.parse(Folio::Ai::Providers::Dummy.new.complete(prompt:, suggestion_count: 3))
    texts = response.fetch("suggestions").map { |suggestion| suggestion.fetch("text") }

    assert_equal "Dummy perex summarizing the article angle so editors can test copy, accept and undo states without a real AI request.",
                 texts.first
    assert_equal 3, texts.size
    assert texts.none? { |text| text.include?("Generate suggestions") }
  end

  test "defines OpenAI model options from Folio-prefixed ENV with fallback" do
    Folio::Ai::Providers::OpenAi.stub(:models_env_value, " gpt-5.5, gpt-5.5-pro, gpt-5.5 ") do
      assert_equal %w[gpt-5.5 gpt-5.5-pro], Folio::Ai::Providers::OpenAi.models
      assert_equal "gpt-5.5", Folio::Ai::Providers::OpenAi.default_model
    end

    Folio::Ai::Providers::OpenAi.stub(:models_env_value, " ") do
      assert_equal [Folio::Ai::Providers::OpenAi::DEFAULT_MODEL], Folio::Ai::Providers::OpenAi.models
      assert_equal Folio::Ai::Providers::OpenAi::DEFAULT_MODEL, Folio::Ai::Providers::OpenAi.default_model
    end
  end

  test "reads OpenAI API key from Folio-prefixed ENV" do
    ENV.stub(:[], ->(key) { key == "FOLIO_AI_OPENAI_API_KEY" ? "secret" : nil }) do
      assert_equal "secret", Folio::Ai.openai_api_key
    end

    ENV.stub(:[], ->(key) { key == "OPENAI_API_KEY" ? "ignored" : nil }) do
      assert_nil Folio::Ai.openai_api_key
    end
  end

  test "builds available provider instances" do
    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      Folio::Ai::Providers::OpenAi.stub(:available?, false) do
        provider = Folio::Ai.provider_for(key: :dummy)

        assert_instance_of Folio::Ai::Providers::Dummy, provider
        assert_equal Folio::Ai::Providers::Dummy::DEFAULT_MODEL, provider.model
      end
    end
  end
end
