# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::ListGroupComponent < Folio::Console::ApplicationComponent
  def initialize(file:, ratio:, thumbnail_size_keys:, updated_thumbnails_crop: false)
    @file = file
    @ratio = ratio
    @thumbnail_size_keys = thumbnail_size_keys
    @updated_thumbnails_crop = updated_thumbnails_crop
  end

  private
    # The "regular" group holds non-crop sizes - no representative, no count.
    def regular?
      @ratio == "regular"
    end

    def ratio_label
      regular? ? t(".regular") : @ratio.tr(":", "×")
    end

    # Optional host-app usage label (Folio::File#thumbnail_ratio_label override).
    def usage_label
      return if regular?

      @file.thumbnail_ratio_label(@ratio, @thumbnail_size_keys).presence
    end

    def variants_count
      @thumbnail_size_keys.size
    end

    def representative_url
      return if regular?

      @representative_url ||= Folio::Console::Files::Show::Thumbnails::RepresentativeImage
                                .representative_url(file: @file,
                                                    keys: @thumbnail_size_keys,
                                                    include_doader: @updated_thumbnails_crop)
    end

    def representative_data
      stimulus_thumbnail(src: representative_url)
    end
end
