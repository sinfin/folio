require_dependency 'folio/concerns/thumbnails'

module Folio
  class Image < Folio::File
    include Thumbnails

    VALID_FORMATS = %i{jpeg jpg png bmp svg gif}

    validates_property :format, of: :file, in: VALID_FORMATS,
                       case_sensitive: false,
                       message: I18n.t('dragonfly.invalid_format', formats: VALID_FORMATS.join(', ')),
                       if: :file_changed?

    def as_json(options = {})
      super(options).update(file_size: ActiveSupport::NumberHelper.number_to_human_size(self.file_size))
    end
  end
end
