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
    assert_equal "Use a calmer tone.", instruction.instruction
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

    def enabled_settings(prompt: "Write a title")
      {
        enabled: true,
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
