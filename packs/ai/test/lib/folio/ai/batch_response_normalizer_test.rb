# frozen_string_literal: true

require "test_helper"

class Folio::Ai::BatchResponseNormalizerTest < ActiveSupport::TestCase
  test "normalizes suggestions_by_field response" do
    fields = {
      "title" => Folio::Ai::Field.new(key: :title, character_limit: 120),
      "perex" => Folio::Ai::Field.new(key: :perex, character_limit: 400),
    }
    raw_response = {
      suggestions_by_field: {
        title: [
          { text: "Generated title" },
        ],
        perex: [
          { text: "Generated perex" },
        ],
      },
    }.to_json

    suggestions = Folio::Ai::BatchResponseNormalizer.new(raw_response:,
                                                         fields:).call

    assert_equal ["Generated title"], suggestions.fetch("title").map(&:text)
    assert_equal ["Generated perex"], suggestions.fetch("perex").map(&:text)
  end

  test "rejects missing field suggestions" do
    fields = {
      "title" => Folio::Ai::Field.new(key: :title),
      "perex" => Folio::Ai::Field.new(key: :perex),
    }
    raw_response = {
      suggestions_by_field: {
        title: [
          { text: "Generated title" },
        ],
      },
    }.to_json

    assert_raises(Folio::Ai::ResponseInvalidError) do
      Folio::Ai::BatchResponseNormalizer.new(raw_response:,
                                             fields:).call
    end
  end
end
