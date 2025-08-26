# frozen_string_literal: true

module Folio::Tiptap::Model
  extend ActiveSupport::Concern

  class_methods do
    def has_folio_tiptap_content(field = :tiptap_content)
      define_method("#{field}=") do |value|
        ftc = Folio::Tiptap::Content.new(record: self)
        result = ftc.convert_and_sanitize_value(value)

        if result[:ok]
          super(result[:value])
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
    before_validation :convert_titap_fields_to_hashes_and_sanitize
    validate :validate_tiptap_fields
  end

  def convert_titap_fields_to_hashes_and_sanitize
    self.class.folio_tiptap_fields.each do |field|
      value = send(field)

      if value.is_a?(String) && value.present?
        begin
          parsed_value = JSON.parse(value)
          send("#{field}=", parsed_value)
        rescue JSON::ParserError
          errors.add(field, :tiptap_invalid_json)
        end
      end
    end
  end

  def validate_tiptap_fields
    self.class.folio_tiptap_fields.each do |field|
      value = send(field)
      next if value.blank?

      unless value.is_a?(Hash)
        errors.add(field, :tiptap_must_be_hash_or_json)
        next
      end

      unless value[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]].is_a?(Hash)
        errors.add(field, :tiptap_must_have_content_key, content_key: Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content])
        next
      end

      if value[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]]["type"] != "doc"
        errors.add(field, :tiptap_root_node_must_be_doc)
        next
      end
    end
  end

  def tiptap_config
    Folio::Tiptap.config
  end
end
