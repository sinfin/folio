# frozen_string_literal: true

module Folio::Tiptap::Model
  extend ActiveSupport::Concern

  class_methods do
    def has_folio_tiptap_content(field = :tiptap_content)
      define_method("#{field}=") do |value|
        if value.is_a?(Hash)
          super(value)
        elsif value.is_a?(String) && value.present?
          begin
            parsed_value = JSON.parse(value)
            super(parsed_value)
          rescue JSON::ParserError
            Rails.logger.error "Did not assign an invalid JSON string for #{self} / #{field}: #{value}"
          end
        else
          Rails.logger.error "Did not assign an invalid value type for #{self} / #{field}: #{value.class.name}"
        end
      end
    end

    def has_folio_tiptap?
      folio_tiptap_fields.present?
    end

    def folio_tiptap_fields
      %w[tiptap_content]
    end
  end

  included do
    before_validation :convert_titap_fields_to_hashes
    validate :validate_tiptap_fields
  end

  def convert_titap_fields_to_hashes
    self.class.folio_tiptap_fields.each do |field|
      value = send(field)

      if value.is_a?(String) && value.present?
        begin
          parsed_value = JSON.parse(value)
          send("#{field}=", parsed_value)
        rescue JSON::ParserError
          errors.add(field, "is not a valid JSON string")
        end
      end
    end
  end

  def validate_tiptap_fields
    self.class.folio_tiptap_fields.each do |field|
      value = send(field)
      next if value.blank?

      unless value.is_a?(Hash)
        errors.add(field, "must be a Hash or a valid JSON string")
        next
      end
    end
  end

  def tiptap_config
    Folio::Tiptap.config
  end
end
