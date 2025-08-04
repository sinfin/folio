# frozen_string_literal: true

module Folio::Tiptap::Model
  extend ActiveSupport::Concern

  class_methods do
    def has_folio_tiptap?
      folio_tiptap_fields.present?
    end

    def folio_tiptap_fields
      %w[tiptap_content]
    end
  end

  included do
    before_validation :convert_titap_fields_to_hashes
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

  def tiptap_config
    Folio::Tiptap.config
  end
end
