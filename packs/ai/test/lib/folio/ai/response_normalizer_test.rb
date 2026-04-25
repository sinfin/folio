# frozen_string_literal: true

require "test_helper"

class Folio::Ai::ResponseNormalizerTest < ActiveSupport::TestCase
  test "normalizes JSON suggestion contract" do
    field = Folio::Ai::Field.new(key: :title)
    raw_response = {
      suggestions: [
        {
          key: "formal",
          text: "Generated title",
          meta: {
            tone_label: "Formal",
          },
        },
      ],
    }.to_json

    suggestions = Folio::Ai::ResponseNormalizer.new(raw_response:, field:).call

    assert_equal 1, suggestions.length
    assert_equal "formal", suggestions.first.key
    assert_equal "Generated title", suggestions.first.text
    assert_equal 15, suggestions.first.char_count
    assert_equal({ tone_label: "Formal" }, suggestions.first.meta)
  end

  test "normalizes array of strings" do
    field = Folio::Ai::Field.new(key: :title)

    suggestions = Folio::Ai::ResponseNormalizer.new(raw_response: ["One", "Two"],
                                                    field:).call

    assert_equal ["One", "Two"], suggestions.map(&:text)
    assert_equal %w[1 2], suggestions.map(&:key)
  end

  test "limits suggestion count" do
    field = Folio::Ai::Field.new(key: :title)

    suggestions = Folio::Ai::ResponseNormalizer.new(raw_response: %w[One Two Three],
                                                    field:,
                                                    suggestion_count: 2).call

    assert_equal ["One", "Two"], suggestions.map(&:text)
  end

  test "flags over-limit suggestions" do
    field = Folio::Ai::Field.new(key: :title, character_limit: 3)

    suggestions = Folio::Ai::ResponseNormalizer.new(raw_response: ["Long title"],
                                                    field:).call

    assert suggestions.first.meta[:over_limit]
    assert_equal 3, suggestions.first.meta[:character_limit]
  end

  test "rejects malformed response" do
    field = Folio::Ai::Field.new(key: :title)

    assert_raises(Folio::Ai::ResponseInvalidError) do
      Folio::Ai::ResponseNormalizer.new(raw_response: "not json", field:).call
    end
  end

  test "rejects blank suggestions" do
    field = Folio::Ai::Field.new(key: :title)

    assert_raises(Folio::Ai::ResponseInvalidError) do
      Folio::Ai::ResponseNormalizer.new(raw_response: [" "], field:).call
    end
  end
end
