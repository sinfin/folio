# frozen_string_literal: true

class Folio::Ai::Suggestion
  attr_reader :key,
              :text,
              :char_count,
              :meta

  def initialize(key:, text:, char_count: nil, meta: {})
    @key = key.to_s
    @text = text.to_s
    @char_count = char_count || @text.length
    @meta = meta || {}
  end

  def as_json(_options = nil)
    {
      key:,
      text:,
      char_count:,
      meta:,
    }
  end
end
