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
      !regular? && @label.present?
    end

    def root_class_name
      "f-c-files-show-thumbnails-list-group--regular" if regular?
    end
end
