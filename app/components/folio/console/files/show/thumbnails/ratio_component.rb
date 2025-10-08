# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::RatioComponent < Folio::Console::ApplicationComponent
  def initialize(file:, ratio:, thumbnail_size_keys:)
    @file = file
    @ratio = ratio
    @thumbnail_size_keys = thumbnail_size_keys
  end
end
