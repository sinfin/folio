# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::TextSuggestionGeneratorTest < ActiveSupport::TestCase
  test "builds prompt from site prompt, instructions, form snapshot, and model additional data" do
    record = build_record_with_additional_data
    provider = CapturingProvider.new(response: {
      suggestions: [
        { key: "title", text: "A very long title" },
        { key: "title", text: "Short" },
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

  test "raises response error for provider output with invalid shape" do
    invalid_responses = [
      [{ key: "title", text: "Suggestion" }].to_json,
      { suggestions: { key: "title", text: "Suggestion" } }.to_json,
      { suggestions: ["Suggestion"] }.to_json,
      { suggestions: [{ text: "Missing key" }] }.to_json,
      { suggestions: [{ key: "missing", text: "Unknown key" }] }.to_json,
      { suggestions: [{ key: "title", text: " " }] }.to_json,
    ]

    invalid_responses.each do |response|
      assert_raises(Folio::Ai::ResponseError) do
        generator(provider: CapturingProvider.new(response:)).call
      end
    end
  end

  test "caps provider suggestion count" do
    provider = CapturingProvider.new(response: {
      suggestions: [
        { key: "title", text: "First" },
        { key: "title", text: "Second" },
        { key: "title", text: "Third" },
        { key: "title", text: "Fourth" },
      ],
    }.to_json)

    suggestions = generator(provider:,
                            suggestion_count: 99).call

    assert_equal Folio::Ai::MAX_SUGGESTION_COUNT, provider.suggestion_count
    assert_equal %w[First Second Third], suggestions.map { |suggestion| suggestion[:text] }
  end

  test "resolves missing field label in the current locale" do
    provider = CapturingProvider.new(response: { suggestions: [{ key: "title", text: "Suggestion" }] }.to_json)

    I18n.with_locale(:cs) do
      generator(provider:,
                field: { key: "title" }).call
    end

    assert_includes provider.prompt, "Název stránky"
  end

  test "builds one provider prompt for multiple fields" do
    record = build_record_with_additional_data
    provider = CapturingProvider.new(response: {
      suggestions: [
        { key: "title", text: "Grouped title" },
        { key: "perex", text: "Grouped perex copy" },
      ],
    }.to_json)

    suggestions = generator(record:,
                            provider:,
                            key: "meta",
                            fields: [
                              { key: "title", label: "Title", character_limit: 10 },
                              { key: "perex", label: "Perex", character_limit: 400 },
                            ],
                            form_snapshot: { title: "Draft title" },
                            site_prompt: "Write grouped suggestions.",
                            instructions: "Keep fields aligned.",
                            suggestion_count: Folio::Ai::GROUPED_SUGGESTION_COUNT).call_by_field

    assert_equal 1, provider.calls
    assert_equal Folio::Ai::GROUPED_SUGGESTION_COUNT, provider.suggestion_count
    assert_includes provider.prompt, "\"fields\""
    assert_includes provider.prompt, "\"title\""
    assert_includes provider.prompt, "\"perex\""
    assert_includes provider.prompt, "Write grouped suggestions."
    assert_includes provider.prompt, "Keep fields aligned."
    assert_includes provider.prompt, "meta"
    assert_equal %w[title perex], suggestions.keys
    assert_equal "Grouped title", suggestions.fetch("title").first[:text]
    assert_equal 13, suggestions.fetch("title").first[:character_count]
    assert_equal 10, suggestions.fetch("title").first[:character_limit]
    assert_equal true, suggestions.fetch("title").first[:over_character_limit]
    assert_equal "Grouped perex copy", suggestions.fetch("perex").first[:text]
  end

  test "raises response error when provider omits a requested field" do
    provider = CapturingProvider.new(response: {
      suggestions: [
        { key: "title", text: "Grouped title" },
      ],
    }.to_json)

    assert_raises(Folio::Ai::ResponseError) do
      generator(provider:,
                fields: [
                  { key: "title", label: "Title" },
                  { key: "perex", label: "Perex" },
                ]).call_by_field
    end
  end

  private
    def generator(site: Dummy::Site.new,
                  record: Folio::Page.new,
                  provider: CapturingProvider.new(response: { suggestions: [{ key: "title", text: "Suggestion" }] }.to_json),
                  field: { key: "title", label: "Title" },
                  fields: nil,
                  key: nil,
                  form_snapshot: {},
                  site_prompt: "Write a useful suggestion.",
                  instructions: nil,
                  suggestion_count: Folio::Ai::DEFAULT_SUGGESTION_COUNT)
      Folio::Ai::TextSuggestionGenerator.new(record:,
                                             site:,
                                             record_key: "folio_pages",
                                             field:,
                                             fields:,
                                             key:,
                                             form_snapshot:,
                                             provider:,
                                             site_prompt:,
                                             instructions:,
                                             suggestion_count:)
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
                  :suggestion_count,
                  :calls

      def initialize(response:)
        @response = response
        @calls = 0
      end

      def complete(prompt:, suggestion_count:)
        @calls += 1
        @prompt = prompt
        @suggestion_count = suggestion_count
        @response
      end
    end
end
