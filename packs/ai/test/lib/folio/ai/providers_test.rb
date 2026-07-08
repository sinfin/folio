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
        assert_equal Folio::Ai::DEFAULT_DUMMY_MODEL, provider.model
      end
    end
  end
end
