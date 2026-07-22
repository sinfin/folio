# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::RatioComponent < Folio::Console::ApplicationComponent
  def initialize(file:, ratio:, ratio_label:, thumbnail_size_keys:, updated_thumbnails_crop: false)
    @file = file
    @ratio = ratio
    @ratio_label = ratio_label
    @thumbnail_size_keys = thumbnail_size_keys
    @updated_thumbnails_crop = updated_thumbnails_crop
  end

  attr_reader :ratio_label
end
