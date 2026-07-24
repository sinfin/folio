# frozen_string_literal: true

class Folio::Console::Files::Show::ThumbnailsComponent < Folio::Console::ApplicationComponent
  def initialize(file:, updated_thumbnail_size_keys: [])
    @file = file
    @updated_thumbnail_size_keys = updated_thumbnail_size_keys
  end

  def main_crop_groups
    thumbnail_groups["main_crop"]
  end

  def crop_groups
    thumbnail_groups["crop"]
  end

  def regular_groups
    thumbnail_groups["regular"]
  end

  private
    def thumbnail_groups
      @thumbnail_groups ||= Folio::Console::Files::ThumbnailGroups.call(file: @file,
                                                                        site: Folio::Current.site)
    end

    def group_updated?(group)
      (@updated_thumbnail_size_keys & group.fetch("sizes")).any?
    end

    def before_render
      @readonly = !can_now?(:update, @file)
    end
end
