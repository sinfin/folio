# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::RatioComponent < Folio::Console::ApplicationComponent
  def initialize(file:, ratio:, thumbnail_size_keys:, updated_thumbnails_crop: false)
    @file = file
    @ratio = ratio
    @thumbnail_size_keys = thumbnail_size_keys
    @updated_thumbnails_crop = updated_thumbnails_crop
  end

  def label
    @file.thumbnail_ratio_label(@ratio, @thumbnail_size_keys).presence || @ratio
  end

  def variants_count
    @thumbnail_size_keys.size
  end

  def representative_key
    Folio::Console::Files::Show::Thumbnails::RepresentativeImage
      .representative_thumbnail_size_key(@thumbnail_size_keys)
  end
end
