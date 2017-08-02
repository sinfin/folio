module Folio
  class Image < Folio::File
    # include Thumbnails

    VALID_FORMATS = %i{jpeg jpg png bmp svg gif}

    validates_property :format, of: :attachment, in: VALID_FORMATS,
                       case_sensitive: false,
                       message: I18n.t('dragonfly.invalid_format', formats: VALID_FORMATS.join(', ')),
                       if: :attachment_changed?
  end
end
