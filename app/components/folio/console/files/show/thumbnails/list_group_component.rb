# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::ListGroupComponent < Folio::Console::ApplicationComponent
  def initialize(file:, ratio:, ratio_label:, label: nil, thumbnail_size_keys:, updated_thumbnails_crop: false)
    @file = file
    @ratio = ratio
    @ratio_label = ratio_label
    @label = label
    @thumbnail_size_keys = thumbnail_size_keys
    @updated_thumbnails_crop = updated_thumbnails_crop
  end

  private
    # The "regular" group holds non-crop sizes - no representative, no count.
    def regular?
      @ratio == "regular"
    end

    def display_ratio_label
      return t(".regular") if regular? && @ratio_label == @ratio

      @ratio_label
    end

    def label?
      @label.present?
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
