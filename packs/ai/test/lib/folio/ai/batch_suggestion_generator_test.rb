# frozen_string_literal: true

require "test_helper"

class Folio::Ai::BatchSuggestionGeneratorTest < ActiveSupport::TestCase
  class FakeBatchProviderAdapter
    attr_reader :calls

    def initialize
      @calls = []
    end

    def generate_batch_suggestions(prompt:, field:, fields:, suggestion_count:)
      calls << {
        prompt:,
        field:,
        fields:,
        suggestion_count:,
      }

      fields.index_with do |field_request|
        [
          Folio::Ai::Suggestion.new(key: 1,
                                    text: "Generated #{field_request.key}"),
        ]
      end.transform_keys { |field_request| field_request.key.to_s }
    end
  end

  setup do
    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(key: :articles,
                                   record_class_name: "Folio::Page",
                                   fields: [
                                     Folio::Ai::Field.new(key: :title,
                                                          character_limit: 120),
                                     Folio::Ai::Field.new(key: :perex,
                                                          character_limit: 400),
                                     Folio::Ai::Field.new(key: :all_ai_inputs),
                                   ])

    @site = create_site(force: true)
    @site.update!(ai_settings: enabled_settings)
    @user = create(:folio_user, auth_site: @site)
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "generates one suggestion per output field through one provider call" do
    adapter = FakeBatchProviderAdapter.new

    result = with_ai_enabled do
      generator(provider_adapter: adapter).call
    end

    assert_equal 1, adapter.calls.length
    assert_equal 1, adapter.calls.first[:suggestion_count]
    assert_equal "all_ai_inputs", adapter.calls.first[:field].key
    assert_equal %w[title perex], adapter.calls.first[:fields].map(&:key)
    assert_includes adapter.calls.first[:prompt], "Write every AI input."
    assert_not_includes adapter.calls.first[:prompt], "Write a title."
    assert_not_includes adapter.calls.first[:prompt], "Write a perex."
    assert_includes adapter.calls.first[:prompt], '"current_title": "Current title"'
    assert_equal "Generated title", result.results.fetch("ai_title").suggestions.first.text
    assert_equal "Generated perex", result.results.fetch("ai_perex").suggestions.first.text
  end

  test "uses wrapper user instruction instead of wrapper default prompt" do
    adapter = FakeBatchProviderAdapter.new

    with_ai_enabled do
      generator(provider_adapter: adapter,
                instructions: "Use only this batch prompt.").call
    end

    assert_includes adapter.calls.first[:prompt], "Use only this batch prompt."
    assert_not_includes adapter.calls.first[:prompt], "Write every AI input."
    assert_not_includes adapter.calls.first[:prompt], "Write a title."
  end

  private
    def with_ai_enabled(&)
      with_ai_config(enabled: true) do
        Folio::Ai.config.stub(:provider_api_key_env_values, { openai: "secret" }, &)
      end
    end

    def generator(provider_adapter:, fields: [field_params(:title), field_params(:perex)], instructions: nil)
      Folio::Ai::BatchSuggestionGenerator.new(site: @site,
                                              user: @user,
                                              integration_key: :articles,
                                              field_key: :all_ai_inputs,
                                              fields:,
                                              context: { current_title: "Current title" },
                                              instructions:,
                                              provider_adapter:)
    end

    def field_params(field_key, component_id: "ai_#{field_key}")
      {
        integration_key: "articles",
        field_key: field_key.to_s,
        component_id:,
        field_label: field_key.to_s.humanize,
      }
    end

    def enabled_settings
      {
        enabled: true,
        integrations: {
          articles: {
            fields: {
              title: {
                prompt: "Write a title.",
              },
              perex: {
                prompt: "Write a perex.",
              },
              all_ai_inputs: {
                prompt: "Write every AI input.",
              },
            },
          },
        },
      }
    end
end
