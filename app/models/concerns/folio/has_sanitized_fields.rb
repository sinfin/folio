# frozen_string_literal: true

module Folio::HasSanitizedFields
  extend ActiveSupport::Concern

  class_methods do
    def has_sanitized_fields(*fields)
      before_save :sanitize_fields

      define_singleton_method :fields_to_sanitize do
        fields
      end
    end

    def sanitize_field_arguments
      {
        tags: [],
        attributes: []
      }
    end
  end

  private
    def sanitize_fields
      self.class.fields_to_sanitize.each { |field| sanitize_field(field) }
    end

    def sanitize_field(field)
      return unless respond_to?(field)

      value = send(field)

      if value.present? && value.is_a?(String)
        send("#{field}=", ActionController::Base.helpers.sanitize(value, self.class.sanitize_field_arguments))
      end
    end
end
