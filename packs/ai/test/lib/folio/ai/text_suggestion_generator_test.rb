# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::TextSuggestionGeneratorTest < ActiveSupport::TestCase
  test "builds prompt from site prompt, instructions, form snapshot, and model additional data" do
    record = build_record_with_additional_data
    provider = CapturingProvider.new(response: {
      suggestions: [
        { text: "A very long title" },
        { text: "Short" },
      ],
    }.to_json)

    suggestions = generator(record:,
                            provider:,
                            field: { key: "title", label: "Title", character_limit: 10 },
                            form_snapshot: { title: "Draft title" },
                            site_prompt: "Write a concise title.",
                            instructions: "Use Czech. Be direct.").call

    assert_includes provider.prompt, "Draft title"
    assert_includes provider.prompt, "Write a concise title."
    assert_includes provider.prompt, "Use Czech."
    assert_includes provider.prompt, "Be direct."
    assert_includes provider.prompt, "category"
    assert_equal 3, provider.suggestion_count
    assert_equal ["A very long title", "Short"], suggestions.map { |suggestion| suggestion[:text] }
    assert_equal 17, suggestions.first[:character_count]
    assert_equal 10, suggestions.first[:character_limit]
    assert_equal true, suggestions.first[:over_character_limit]
    assert_equal false, suggestions.second[:over_character_limit]
  end

  test "raises response error for invalid provider output" do
    assert_raises(Folio::Ai::ResponseError) do
      generator(provider: CapturingProvider.new(response: "not-json")).call
    end
  end

  private
    def generator(site: Dummy::Site.new,
                  record: Folio::Page.new,
                  provider: CapturingProvider.new(response: { suggestions: [{ text: "Suggestion" }] }.to_json),
                  field: { key: "title", label: "Title" },
                  form_snapshot: {},
                  site_prompt: "Write a useful suggestion.",
                  instructions: nil)
      Folio::Ai::TextSuggestionGenerator.new(record:,
                                             site:,
                                             record_key: "folio_pages",
                                             field:,
                                             form_snapshot:,
                                             provider:,
                                             site_prompt:,
                                             instructions:)
    end

    def build_record_with_additional_data
      Folio::Page.new.tap do |record|
        record.define_singleton_method(:folio_ai_additional_data) do |field_key:, form_snapshot:|
          {
            category: "News",
            requested_field: field_key,
            snapshot_title: form_snapshot["title"],
          }
        end
      end
    end

    class CapturingProvider
      attr_reader :prompt,
                  :suggestion_count

      def initialize(response:)
        @response = response
      end

      def complete(prompt:, suggestion_count:)
        @prompt = prompt
        @suggestion_count = suggestion_count
        @response
      end
    end
end
