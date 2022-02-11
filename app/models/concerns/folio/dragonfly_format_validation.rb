# frozen_string_literal: true

module Folio::DragonflyFormatValidation
  extend ActiveSupport::Concern

  class_methods do
    def validate_file_format(formats = %w[jpeg png bmp gif svg tiff])
      mime_types = []

      formats.each do |f|
        mime_types << "image/#{f}"

        if f == "svg"
          mime_types << "image/svg+xml"
        end
      end

      define_singleton_method :valid_mime_types do
        mime_types
      end

      define_singleton_method :valid_mime_types_message do
        I18n.t("activerecord.errors.messages.file_format",
               types: formats.join(", "))
      end

      validate :validate_file_format_via_mime_type
    end
  end

  private
    def validate_file_format_via_mime_type
      if file_mime_type.blank?
        errors.add(:file_mime_type, :blank)
      else
        if self.class.valid_mime_types.exclude?(file_mime_type)
          errors.add(:file_mime_type, self.class.valid_mime_types_message)
        end
      end
    end
end
