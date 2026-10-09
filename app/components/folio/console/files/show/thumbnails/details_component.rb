# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::DetailsComponent < Folio::Console::ApplicationComponent
  def initialize(file:, details_id:, updated_thumbnail_size_keys: [])
    @file = file
    @details_id = details_id
    @updated_thumbnail_size_keys = updated_thumbnail_size_keys
  end

  private
    def thumbnails?
      @file.thumbnail_sizes.present?
    end

    def crop_groups
      thumbnail_groups["crop"]
    end

    def regular_groups
      thumbnail_groups["regular"]
    end

    def thumbnail_groups
      @thumbnail_groups ||= Folio::Console::Files::ThumbnailGroups.call(file: @file,
                                                                         site: Folio::Current.site)
    end

    def group_updated?(group)
      (@updated_thumbnail_size_keys & group.fetch("sizes")).any?
    end
end
