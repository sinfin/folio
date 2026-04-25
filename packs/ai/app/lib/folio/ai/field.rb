# frozen_string_literal: true

class Folio::Ai::Field
  attr_reader :key,
              :label,
              :response_format,
              :auto_attach,
              :input_types,
              :character_limit,
              :metadata

  def initialize(key:,
                 label: nil,
                 response_format: :plain_text,
                 auto_attach: false,
                 input_types: %i[string text],
                 character_limit: nil,
                 **metadata)
    @key = normalize_key(key)
    @label = label.presence || @key.humanize
    @response_format = response_format.to_sym
    @auto_attach = !!auto_attach
    @input_types = Array(input_types).map(&:to_sym)
    @character_limit = character_limit
    @metadata = metadata
  end

  def auto_attach?
    auto_attach
  end

  private
    def normalize_key(key)
      key.to_s.strip
    end
end
