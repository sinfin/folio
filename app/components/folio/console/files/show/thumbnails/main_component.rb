# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::MainComponent < Folio::Console::ApplicationComponent
  def initialize(file:, details_id:, updated_thumbnail_size_keys: [])
    @file = file
    @details_id = details_id
    @updated_thumbnail_size_keys = updated_thumbnail_size_keys
  end

  def self.details_id(file)
    "f-c-files-show-thumbnails-details-#{file.id}"
  end

  private
    def render?
      @file.thumbnail_sizes.present?
    end

    def main_crop_groups
      thumbnail_groups["main_crop"]
    end

    def thumbnail_groups
      @thumbnail_groups ||= Folio::Console::Files::ThumbnailGroups.call(file: @file,
                                                                         site: Folio::Current.site)
    end

    def group_updated?(group)
      (@updated_thumbnail_size_keys & group.fetch("sizes")).any?
    end

    def data
      stimulus_controller("f-c-files-show-thumbnails-main",
                          values: {
                            expanded: false,
                            details_id: @details_id,
                          })
    end

    def toggle_data
      stimulus_data(target: "toggle", action: { click: "toggleDetails" })
    end
end
