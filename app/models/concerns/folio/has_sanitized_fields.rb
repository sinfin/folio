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
  end

  private
    def sanitize_fields
      self.class.fields_to_sanitize.each { |field| sanitize_field(field) }
    end

    def sanitize_field(field)
      value = send(field)

      if value.present? && value.is_a?(String)
        send("#{field}=", ActionController::Base.helpers.sanitize(value, tags: [], attributes: []))
      end
    end
end
