# frozen_string_literal: true

class Folio::Ai::Field
  SUPPORTED_INPUT_TYPES = %i[string text].freeze

  attr_reader :key,
              :response_format,
              :auto_attach,
              :character_limit,
              :metadata

  def initialize(key:,
                 label: nil,
                 response_format: :plain_text,
                 auto_attach: false,
                 character_limit: nil,
                 **metadata)
    @key = normalize_key(key)
    @label = label.presence
    @response_format = response_format.to_sym
    @auto_attach = !!auto_attach
    @character_limit = character_limit
    @metadata = metadata
  end

  def label(record_class: nil)
    @label.presence || record_class&.human_attribute_name(key) || key.humanize
  end

  def input_type(record_class:)
    normalize_input_type(attribute_type(record_class, key))
  end

  def supports_input_type?(input_type, record_class:)
    self.input_type(record_class:) == input_type.to_sym
  end

  def auto_attach?
    auto_attach
  end

  private
    def attribute_type(record_class, attribute)
      direct_type = record_class_attribute_type(record_class, attribute)
      return direct_type if supported_input_type?(direct_type)

      localized_attribute_types(record_class, attribute).find do |localized_type|
        supported_input_type?(localized_type)
      end
    end

    def localized_attribute_types(record_class, attribute)
      return [] unless record_class.respond_to?(:locale_columns)

      Array(record_class.locale_columns(attribute.to_sym)).filter_map do |column|
        record_class_attribute_type(record_class, column)
      end
    end

    def record_class_attribute_type(record_class, attribute)
      return unless record_class&.respond_to?(:type_for_attribute)

      record_class.type_for_attribute(attribute.to_s)&.type
    end

    def normalize_input_type(input_type)
      input_type if supported_input_type?(input_type)
    end

    def supported_input_type?(input_type)
      SUPPORTED_INPUT_TYPES.include?(input_type)
    end

    def normalize_key(key)
      key.to_s.strip
    end
end
