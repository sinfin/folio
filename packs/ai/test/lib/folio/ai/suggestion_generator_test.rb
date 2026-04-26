# frozen_string_literal: true

require "test_helper"

class Folio::Ai::SuggestionGeneratorTest < ActiveSupport::TestCase
  class FakeProviderAdapter
    attr_reader :calls

    def initialize(error: nil)
      @error = error
      @calls = []
    end

    def generate_suggestions(prompt:, field:, suggestion_count:)
      calls << {
        prompt:,
        field:,
        suggestion_count:,
      }

      raise @error if @error

      [
        Folio::Ai::Suggestion.new(key: "1", text: "Generated title"),
      ]
    end
  end

  setup do
    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(:articles, fields: [
      Folio::Ai::Field.new(key: :title, character_limit: 120),
    ])

    @site = create_site(force: true)
    @site.update!(ai_settings: enabled_settings)
    @user = create(:folio_user, auth_site: @site)
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "generates suggestions through configured adapter" do
    adapter = FakeProviderAdapter.new
    Folio::Ai::UserInstruction.upsert_instruction!(user: @user,
                                                   site: @site,
                                                   integration_key: :articles,
                                                   field_key: :title,
                                                   instruction: "Make it concise.")

    result = with_ai_enabled do
      generator(provider_adapter: adapter,
                context: { title: "Original" }).call
    end

    assert result.success?
    assert_equal ["Generated title"], result.suggestions.map(&:text)
    assert_equal :openai, result.provider
    assert_equal "gpt-5.5", result.model
    assert_equal "Make it concise.", result.user_instruction
    assert_equal 1, adapter.calls.length
    assert_includes adapter.calls.first[:prompt], "Make it concise."
    assert_includes adapter.calls.first[:prompt], '"title": "Original"'
    assert_equal "title", adapter.calls.first[:field].key
  end

  test "does not call provider when prompt is unavailable" do
    @site.update!(ai_settings: enabled_settings(prompt: ""))
    adapter = FakeProviderAdapter.new

    result = with_ai_enabled do
      generator(provider_adapter: adapter).call
    end

    assert_not result.success?
    assert_equal :prompt_missing, result.error_code
    assert_empty adapter.calls
  end

  test "persists explicit instruction before generation" do
    adapter = FakeProviderAdapter.new(error: Folio::Ai::ProviderError.new("failure"))

    result = with_ai_enabled do
      generator(provider_adapter: adapter,
                instructions: "Use a calmer tone.",
                persist_instructions: true).call
    end

    instruction = Folio::Ai::UserInstruction.find_or_initialize_for(user: @user,
                                                                    site: @site,
                                                                    integration_key: :articles,
                                                                    field_key: :title)

    assert_not result.success?
    assert_equal :provider_error, result.error_code
    assert_equal "Use a calmer tone.", result.user_instruction
    assert_equal "Use a calmer tone.", instruction.instruction
  end

  test "falls back to provider default when configured model is unavailable" do
    @site.update!(ai_settings: enabled_settings(default_model: "retired-model"))
    requested_models = []
    events = []
    subscriber = ActiveSupport::Notifications.subscribe(/folio\.ai\./) do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end

    provider_factory = lambda do |provider:, model:, api_key: nil|
      assert_equal :openai, provider
      assert_nil api_key
      requested_models << model

      if model == "retired-model"
        FakeProviderAdapter.new(error: Folio::Ai::ProviderModelUnavailableError.new("missing"))
      else
        FakeProviderAdapter.new
      end
    end

    result = with_ai_enabled do
      with_config(folio_ai_model_fallback_enabled: true) do
        Folio::Ai.stub(:provider_adapter, provider_factory) do
          generator.call
        end
      end
    end

    assert result.success?
    assert_equal ["retired-model", "gpt-5.5"], requested_models
    assert_equal "gpt-5.5", result.model
    assert_equal :model_fallback, result.warnings.first[:code]
    assert_equal "retired-model", result.warnings.first[:requested_model]
    assert_equal "gpt-5.5", result.warnings.first[:fallback_model]

    fallback_event = events.find { |event| event.name == "folio.ai.provider_model_fallback" }
    success_event = events.find { |event| event.name == "folio.ai.suggestion_generation_succeeded" }

    assert_equal "retired-model", fallback_event.payload[:requested_model]
    assert_equal "gpt-5.5", fallback_event.payload[:fallback_model]
    assert_equal "retired-model", success_event.payload[:requested_model]
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  test "returns provider error when provider API key is missing" do
    original_value = ENV.delete("OPENAI_API_KEY")

    result = with_ai_enabled do
      generator.call
    end

    assert_not result.success?
    assert_equal :provider_error, result.error_code
  ensure
    ENV["OPENAI_API_KEY"] = original_value if original_value
  end

  test "does not call provider when cost guard rejects prompt" do
    adapter = FakeProviderAdapter.new

    result = with_ai_enabled do
      with_config(folio_ai_max_prompt_chars: 5) do
        generator(provider_adapter: adapter,
                  context: { body: "Long context" }).call
      end
    end

    assert_not result.success?
    assert_equal :cost_limit_exceeded, result.error_code
    assert_empty adapter.calls
  end

  test "tracks generation without prompt or content payload" do
    adapter = FakeProviderAdapter.new
    events = []
    subscriber = ActiveSupport::Notifications.subscribe(/folio\.ai\./) do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end

    with_ai_enabled do
      generator(provider_adapter: adapter,
                context: { body: "Sensitive content" }).call
    end

    names = events.map(&:name)
    payloads = events.map(&:payload)

    assert_includes names, "folio.ai.suggestion_generation_requested"
    assert_includes names, "folio.ai.suggestion_generation_succeeded"
    assert payloads.all? { |payload| payload.key?(:site_id) }
    assert payloads.none? { |payload| payload.value?("Sensitive content") }
    assert payloads.none? { |payload| payload.value?("Write a title") }
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  private
    def with_ai_enabled(&)
      with_config(folio_ai_enabled: true, &)
    end

    def generator(**options)
      Folio::Ai::SuggestionGenerator.new(site: @site,
                                         user: @user,
                                         integration_key: :articles,
                                         field_key: :title,
                                         **options)
    end

    def enabled_settings(prompt: "Write a title", default_model: nil)
      {
        enabled: true,
        default_model:,
        integrations: {
          articles: {
            fields: {
              title: {
                prompt:,
              },
            },
          },
        },
      }
    end
end
