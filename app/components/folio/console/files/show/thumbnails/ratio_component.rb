# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::RatioComponent < Folio::Console::ApplicationComponent
  def initialize(file:, ratio:, thumbnail_size_keys:, updated_thumbnails_crop: false)
    @file = file
    @ratio = ratio
    @thumbnail_size_keys = thumbnail_size_keys
    @updated_thumbnails_crop = updated_thumbnails_crop
  end

  # Tile label is always the reduced aspect ratio ("16×9"); usage labels from
  # Folio::File#thumbnail_ratio_label belong to the disclosure list groups.
  def label
    @ratio.tr(":", "×")
  end
end
