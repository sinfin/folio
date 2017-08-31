require_dependency 'folio/concerns/thumbnails'

module Folio
  class Image < Folio::File
    include Thumbnails

    paginates_per 11

    VALID_FORMATS = %i{jpeg jpg png bmp svg gif}

    validates_property :format, of: :file, in: VALID_FORMATS,
                       case_sensitive: false,
                       message: I18n.t('dragonfly.invalid_format', formats: VALID_FORMATS.join(', ')),
                       if: :file_changed?
  end
end
