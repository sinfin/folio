# frozen_string_literal: true

# Development-only provider returning deterministic fake suggestions.
class Folio::Ai::Providers::Dummy < Folio::Ai::Providers::Base
  DEFAULT_MODEL = Folio::Ai::DEFAULT_DUMMY_MODEL

  def self.key
    :dummy
  end

  def self.available?
    Rails.env.development?
  end

  def complete(prompt:, suggestion_count:)
    {
      suggestions: suggestion_count.times.map do |index|
        { text: "Dummy suggestion #{index + 1}: #{prompt.to_s.squish.truncate(120)}" }
      end,
    }.to_json
  end
end
