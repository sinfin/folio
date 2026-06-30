# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::RatioComponent < Folio::Console::ApplicationComponent
  def initialize(file:, ratio:, thumbnail_size_keys:, updated_thumbnails_crop: false)
    @file = file
    @ratio = ratio
    @thumbnail_size_keys = thumbnail_size_keys
    @updated_thumbnails_crop = updated_thumbnails_crop
  end

  # Group label. Defaults to the reduced aspect ratio in "W×H" form (e.g.
  # "16×9"); host apps may override Folio::File#thumbnail_ratio_label to name
  # the group differently.
  def label
    @file.thumbnail_ratio_label(@ratio, @thumbnail_size_keys).presence || @ratio.tr(":", "×")
  end
end
