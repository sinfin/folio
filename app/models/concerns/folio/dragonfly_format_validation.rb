# frozen_string_literal: true

module Folio::DragonflyFormatValidation
  extend ActiveSupport::Concern

  class_methods do
    def validate_file_format(formats = %w[jpeg png bmp gif svg tiff])
      validates_property :format,
                         of: :file,
                         in: formats,
                         message: proc { |actual, model|
                           I18n.t('activerecord.errors.messages.file_format',
                                  types: formats.join(', '))
                         }
    end
  end
end
